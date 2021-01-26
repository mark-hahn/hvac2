###
  websocket.coffee
  http server / websocket <-> rx
###

{log, logObj} = require('./log') 'WSOCK'

{noNet} = require './global'
port = (if noNet then 2339 else 1339)

fs          = require 'fs'
util        = require 'util'
url         = require 'url'
$           = require('imprea')()
http        = require 'http'
Primus      = require 'primus'
url         = require 'url'
nodeStatic  = require 'node-static'
scroll      = require '../js/scroll'
html        = require('../www/js/index-html')()
lightsHtml  = require('../www/js/lights-html')()
tvtabHtml   = require('../www/js/tvtab-html')()
mbtabHtml   = require('../www/js/mbtab-html')()
moment      = require 'moment'
{Webhook}   = require('jovo-framework');
bodyParser  = require('body-parser');
jsonParser  = bodyParser.json();
fileServer  = new nodeStatic.Server 'www', cache: 0
connections = []

rooms = ['tvRoom', 'kitchen', 'master', 'guest']
tempsByRoom = {}
tstatByRoom = {}

$.output 'ws_tstat_data', 'light_cmd'

masterSetpoint = null
tvRoomSetpoint = null
seq = 0

writeCodes = (room) ->
  codes = '' + $.log_modeCode_sys + $.log_extAirCode +
               $['log_reqCode_' + room] + $['log_actualCode_' + room]
  for conn in connections
    conn.connection.write
      type: 'codes'
      room: room
      codes: codes.toUpperCase().replace 'V', 'v'

fmtInches = (inches) ->
  inches = +inches
  if inches >= 1    then return inches.toFixed(1)
  if inches >= 0.01 then return inches.toFixed(2).slice(1)
  '0'

writeMbtab = ->
  # sysCode =
  #   $.log_modeCode_sys + $.log_extAirCode + $.log_counts + ''
  # masterCode =
  #   $.log_modeCode_master + $.log_reqCode_master + $.log_actualCode_master + ' ' +
  #   $.log_elapsedCode_master
  sysCode =
    $.log_extAirCode + $.log_counts + ''
  masterCode =
    $.log_reqCode_master + $.log_actualCode_master + ' ' + $.log_elapsedCode_master
  for conn in connections
    if (wxdata = $.weewx_data)
      windDeg = Math.round wxdata.windGustDir
      if !wxdata.windGust   then windGustDir = '---'
      else if windDeg <  12 then windGustDir = 'N'
      else if windDeg <  34 then windGustDir = 'NNE'
      else if windDeg <  57 then windGustDir = 'NE'
      else if windDeg <  79 then windGustDir = 'ENE'
      else if windDeg < 102 then windGustDir = 'E'
      else if windDeg < 124 then windGustDir = 'ESE'
      else if windDeg < 147 then windGustDir = 'SE'
      else if windDeg < 169 then windGustDir = 'SSE'
      else if windDeg < 192 then windGustDir = 'S'
      else if windDeg < 214 then windGustDir = 'SSW'
      else if windDeg < 237 then windGustDir = 'SW'
      else if windDeg < 259 then windGustDir = 'WSW'
      else if windDeg < 282 then windGustDir = 'W'
      else if windDeg < 304 then windGustDir = 'WNW'
      else if windDeg < 327 then windGustDir = 'NW'
      else if windDeg < 349 then windGustDir = 'NNW'
      else                       windGustDir = 'N'

      conn.connection.write
        type:          'mbtab'
        master:         $.temp_master?.toFixed(1) ? '----'
        masterSetpoint: (if masterSetpoint then masterSetpoint.toFixed 1 else '----')
        masterCode:     masterCode.toUpperCase().replace 'V', 'v'
        sysCode:        sysCode.toUpperCase()
        outTemp:        '' + Math.round wxdata.outTemp     ? '0'
        outHumidity:    '' + Math.round wxdata.outHumidity ? '0'
        rain:           '' + fmtInches (wxdata.rain ? 0)
        windSpeed:      '' + Math.round wxdata.windSpeed   ? '0'
        windDir:        '' + Math.round wxdata.windDir     ? '0'
        windGust:       '' + Math.round wxdata.windGust    ? '0'
        windGustDir:    windGustDir

modeUnder = (tstat) ->
  mode = tstat?.mode
  (mode and (mode is 'cool' or mode is 'heat'))

writeTvtab = ->
  for conn in connections
    if (wxdata = $.weewx_data)
      deg225 = 45/2
      windDeg = Math.round wxdata.windGustDir ? 0
      if      windDeg < ( 1 * deg225) then windGustDir = 'N'
      else if windDeg < ( 3 * deg225) then windGustDir = 'NE'
      else if windDeg < ( 5 * deg225) then windGustDir = 'E'
      else if windDeg < ( 7 * deg225) then windGustDir = 'SE'
      else if windDeg < ( 9 * deg225) then windGustDir = 'S'
      else if windDeg < (11 * deg225) then windGustDir = 'SW'
      else if windDeg < (13 * deg225) then windGustDir = 'W'
      else if windDeg < (15 * deg225) then windGustDir = 'NW'
      else                                 windGustDir = 'N'

      if isNaN(wxdata.windGust) then wxdata.windGust = 0
      windGust = Math.round wxdata.windGust
      if windGust == 0 then windGustDir = '--'

      conn.connection.write
        type:          'tvtab'
        tvRoom:         $.temp_tvRoom?.toFixed(1) ? '----'
        tvRoomSetpoint: (if tvRoomSetpoint then tvRoomSetpoint.toFixed 1 else '----') 
        master_under:   modeUnder $.tstat_master
        master:         $.temp_master?.toFixed(0)
        outTemp:        '' + Math.round wxdata.outTemp     ? '0'
        outHumidity:    '' + Math.round wxdata.outHumidity ? '0'
        rain:           '' + fmtInches (wxdata.rain ? 0)
        windGust:       '' + windGust
        windGustDir:         windGustDir

masterWasActive = false;
now = Date.now();
masterOnTime  = now;
masterOffTime = now;
masterOnDuration  = 0;
masterOffDuration = 0;

writeMbtab = ->
  now = Date.now();
  for conn in connections
    if (wxdata = $.weewx_data)
      deg225 = 45/2
      windDeg = Math.round wxdata.windGustDir ? 0
      if      windDeg < ( 1 * deg225) then windGustDir = 'N'
      else if windDeg < ( 3 * deg225) then windGustDir = 'NE'
      else if windDeg < ( 5 * deg225) then windGustDir = 'E'
      else if windDeg < ( 7 * deg225) then windGustDir = 'SE'
      else if windDeg < ( 9 * deg225) then windGustDir = 'S'
      else if windDeg < (11 * deg225) then windGustDir = 'SW'
      else if windDeg < (13 * deg225) then windGustDir = 'W'
      else if windDeg < (15 * deg225) then windGustDir = 'NW'
      else                                 windGustDir = 'N'

      if isNaN(wxdata.windGust) then wxdata.windGust = 0
      windGust = Math.round wxdata.windGust
      if windGust == 0 then windGustDir = '--'

      masterActive = $.ctrl_active['master']
      if masterActive and not masterWasActive
        masterOffDuration = (now - masterOffTime) / 60000
        masterOnTime = now;

      if not masterActive and masterWasActive
        masterOnDuration = (now - masterOnTime) / 60000
        masterOffTime = now;
      
      masterWasActive = masterActive

      conn.connection.write
        type:          'mbtab'

        masterOnOff:   masterOnDuration.toFixed(1) + '/' +
                       masterOffDuration.toFixed(1)

        master:         $.temp_master?.toFixed(1) ? '----'
        masterSetpoint: (if masterSetpoint then masterSetpoint.toFixed 1 else '----') 

        tvRoom_under:   modeUnder $.tstat_tvRoom
        kitchen_under:  modeUnder $.tstat_kitchen
        guest_under:    modeUnder $.tstat_guest

        tvRoom:         $.temp_tvRoom?.toFixed(0)
        kitchen:        $.temp_kitchen?.toFixed(0)
        guest:          $.temp_guest?.toFixed(0)

        outTemp:        '' + Math.round wxdata.outTemp     ? '0'
        outHumidity:    '' + Math.round wxdata.outHumidity ? '0'
        rain:           '' + fmtInches (wxdata.rain ? 0)
        windGust:       '' + windGust
        windGustDir:         windGustDir

ifttt = (cmd,roomIn,temp) ->
  console.log('iftt:', {cmd,roomIn,temp})

  [roomPfx, roomSfx] = roomIn.split('%20');
  room = null
  if      roomPfx is 'living' then room = 'tvRoom'
  else if roomPfx is 'master' then room = 'master'
  else return

  setData = null

  if cmd is 'set' 
    if temp < 60 or temp > 90 then return
    mode = null
    if roomSfx
      if      roomSfx is 'heat' or
              roomSfx is 'heater' then mode = 'heat'
      else if roomSfx is 'ac'   or
              roomSfx is 'cool'   then mode = 'cool'
      else return
    setData = 
      room:      room
      setpoint: +temp
    if mode then setData.mode = mode
  else if cmd is 'off'
    setData = 
      room:  room
      mode: 'off'
  else return
  
  Object.assign tstatByRoom[room], setData

  console.log 'ifttt:', util.inspect tstatByRoom[room]
  $.ws_tstat_data tstatByRoom[room]

  if room is 'master'
    masterSetpoint = tstatByRoom[room].setpoint
    writeMbtab()

  if room is 'tvRoom'
    tvRoomSetpoint = tstatByRoom[room].setpoint
    writeTvtab()
    
  for conn in connections
    conn.connection.write tstatByRoom[room]

module.exports =
  init: ->
    for room in rooms then do (room) =>
      obsName = 'temp_' + room
      $.react obsName, ->
        # log 'recvd temp', temp, connections.length
        temp = $[obsName]
        tempData = {type: 'temp', room, temp}
        tempsByRoom[room] = tempData
        for conn in connections
          conn.connection.write tempData

      $.react 'log_modeCode_sys', 'log_extAirCode',
              'log_reqCode_' + room, 'log_actualCode_' + room
      , -> writeCodes room

    $.react 'temp_master', 
          'tstat_tvRoom', 'tstat_kitchen', 'tstat_guest', 'ctrl_active', 
          'log_modeCode_master', 'log_reqCode_master', 'log_actualCode_master',
          'log_elapsedCode_master',
          'log_sysMode', 'log_modeCode_sys', 'log_extAirCode',
          'weewx_data', 'log_counts', writeMbtab

    $.react 'temp_tvRoom', 'tstat_master',
          'log_modeCode_tvRoom', 'log_reqCode_tvRoom', 'log_actualCode_tvRoom',
          'log_elapsedCode_tvRoom',
          'log_sysMode', 'log_modeCode_sys', 'log_extAirCode',
          'weewx_data', 'log_counts', writeTvtab


srvr = http.createServer (req, res) ->
  log 'req:', req.url

  if req.url.length > 1 and req.url[-1..-1] is '/'
    req.url = req.url[0..-2]

  req.url = switch req.url[0..4]
    when '/hvac' then page = 'hvac';  req.url[5...] or '/'
    when '/tvta' then page = 'tvtab'; req.url[6...] or '/'
    when '/mbta' then page = 'mbtab'; req.url[6...] or '/'
    when '/scro' then req.url
    when '/iftt' then req.url
    else page = 'hvac';  req.url[5...] or '/'  # ''

  log {page, req: req.url}

  if not req.url
    log req.url, 'not found, page:', page
    res.writeHead 404, "Content-Type": "text/plain"

    res.end req.url + ' not found, page:' + page
    return

  if req.url is '/'
    res.writeHead 200, "Content-Type": "text/html"
    res.end switch page
      when 'hvac'   then html
      when 'tvtab'  then tvtabHtml
      when 'mbtab'  then mbtabHtml
      else ''
    return

  if page is 'hvac' and req.url is '/roomStats'
    res.writeHead 200, "Content-Type": "text/json"
    res.end JSON.stringify tstatByRoom
    return

  if req.url is '/tvtab'
    res.writeHead 200, "Content-Type": "text/html"
    res.end tvtabHtml
    return

  if req.url is '/mbtab'
    res.writeHead 200, "Content-Type": "text/html"
    res.end mbtabHtml
    return

  if req.url[0..6] is '/usage/'
    log 'usage-req:', req.url
    try
      res.writeHead 200, "Content-Type": "image/svg+xml"
      res.end fs.readFileSync req.url[6...], 'utf8'
    catch e
      log 'usage read error:', e
      res.writeHead 500, "Content-Type": "text/plain"
      res.end 'Usage file read error: ' + JSON.stringify e
    return

  if req.url[0..6] is '/scroll'
    timespan = req.url[8...] or '8'
    res.writeHead 200, "Content-Type": "image/svg+xml"
    scroll +timespan, res, ->
    return

  if req.url[0..5] is '/ifttt'
    [x,y,cmd,room,temp] = req.url.split('/')
    ifttt(cmd,room,temp)
    res.writeHead 200, "Content-Type": "text/plain"
    res.end 'done'
    return

  req.addListener('end', ->
    fileServer.serve req, res, (err) ->
      if err and req.url[-4..-1] not in ['.map', '.ico']
        log 'No file for:', req.url, err
  ).resume()

srvr.listen port
log 'Listening on port', port

primus = new Primus srvr, iknowhttpsisbetter: yes, pathname: 'hvac/primus'
primus.save 'www/js/primus.js'

primus.on 'connection', (connection) ->
  connId = connection.id.split('$')[0]
  connections.push {id: connId, connection}

  connection.on 'data', (data) ->
    # log 'connection.on data', data

    switch data.type

      when 'setStatVar'
        {room, variable, setData, setHeatAbs} = data

        if variable is 'setpoint' and tstatByRoom[room]
          if setHeatAbs and tstatByRoom['master'].mode is 'heat'
            tstatByRoom[room].setpoint =  setData
            tstatByRoom[room].mode     = 'heat'
            log "setAbs", tstatByRoom[room]
          else
            tstatByRoom[room].setpoint += (if setData is 'up' then +0.5 else -0.5)

          $.ws_tstat_data tstatByRoom[room]
          if room is 'master'
            masterSetpoint = tstatByRoom[room].setpoint
            writeMbtab()
          if room is 'tvRoom'
            tvRoomSetpoint = tstatByRoom[room].setpoint
            writeTvtab()
            
          for conn in connections when conn.id isnt connId and tstatByRoom[data.room]
            conn.connection.write tstatByRoom[data.room]

      when 'tstat'
        tstatByRoom[data.room] = data
        $.ws_tstat_data data
        if data.room is 'master'
          masterSetpoint = (if data.mode in ['cool', 'heat'] then data.setpoint)
          writeMbtab()
        if data.room is 'tvRoom'
          tvRoomSetpoint = (if data.mode in ['cool', 'heat'] then data.setpoint)
          writeTvtab()
        for conn in connections when conn.id isnt connId and tstatByRoom[data.room]
          conn.connection.write tstatByRoom[data.room]

      when 'reqAll'
        for room in rooms
          if tstatByRoom[room]
            tstat = tstatByRoom[room]
            connection.write tstat
            if tstat.room is 'master'
              masterSetpoint = (if tstat.mode in ['cool', 'heat'] then tstat.setpoint)
              writeMbtab()
            if tstat.room is 'tvRoom'
              tvRoomSetpoint = (if tstat.mode in ['cool', 'heat'] then tstat.setpoint)
              writeTvtab()
          if tempsByRoom[room] then connection.write tempsByRoom[room]
          writeCodes room

  connection.on 'end', ->
    leanConns = []
    for conn in connections
      if conn.id isnt connId
        leanConns.push conn
    connections = leanConns
