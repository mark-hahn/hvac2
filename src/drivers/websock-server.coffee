###
  websocket.coffee
  http server / websocket <-> rx
###

{log, logObj} = require('./log') 'WSOCK'

{noNet} = require './global'
port = (if noNet then 2339 else 1339)

fs          = require 'fs'
url         = require 'url'
$           = require('imprea')()
http        = require 'http'
Primus      = require 'primus'
url         = require 'url'
nodeStatic  = require 'node-static'
scroll      = require '../js/scroll'
html        = require('../www/js/index-html')()
lightsHtml  = require('../www/js/lights-html')()
ceilHtml    = require('../www/js/ceil-html')()
moment      = require 'moment'
fileServer  = new nodeStatic.Server 'www', cache: 0
connections = []

rooms = ['tvRoom', 'kitchen', 'master', 'guest']
tempsByRoom = {}
tstatByRoom = {}

$.output 'ws_tstat_data', 'light_cmd'

masterSetpoint = null
seq = 0

writeCodes = (room) ->
  codes = '' + $.log_modeCode_sys + $.log_extAirCode +
               $['log_reqCode_' + room] + $['log_actualCode_' + room]
  for conn in connections
    conn.connection.write
      type: 'codes'
      room: room
      codes: codes.toUpperCase().replace 'V', 'v'

writeCeil = ->
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
      conn.connection.write
        type:          'ceil'
        master:         $.temp_master?.toFixed(1) ? '----'
        masterSetpoint: (if masterSetpoint then masterSetpoint.toFixed 1 else '----')
        masterCode:     masterCode.toUpperCase().replace 'V', 'v'
        sysCode:        sysCode.toUpperCase()
        outTemp:        '' + Math.round wxdata.outTemp     ? '0'
        outHumidity:    '' + Math.round wxdata.outHumidity ? '0'
        rain:           '' + Math.round (wxdata.rain ? 0) * 100
        windSpeed:      '' + Math.round wxdata.windSpeed   ? '0'
        windDir:        '' + Math.round wxdata.windDir     ? '0'
        windGust:       '' + Math.round wxdata.windGust    ? '0'
        windGustDir:    '' + Math.round wxdata.windGustDir ? '0'

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
          'log_modeCode_master', 'log_reqCode_master', 'log_actualCode_master',
          'log_elapsedCode_master',
          'log_sysMode', 'log_modeCode_sys', 'log_extAirCode',
          'weewx_data', 'log_counts', writeCeil

    $.react 'inst_remote', ->
      {remote, btn, action} = $.inst_remote
      if btn < 7 or not tstatByRoom.tvRoom or action isnt 'click' or
         remote not in ['lightsRemote1', 'lightsRemote2']
        return
      tstatByRoom.tvRoom.setpoint += (if btn is 7 then +0.5 else -0.5)
      $.ws_tstat_data tstatByRoom.tvRoom
      for conn in connections
        conn.connection.write tstatByRoom.tvRoom

srvr = http.createServer (req, res) ->
  # log 'req:', req.url
  if req.url.length > 1 and req.url[-1..-1] is '/'
    req.url = req.url[0..-2]
  req.url = switch req.url[0..4]
    when '/hvac' then page = 'hvac';   req.url[5...] or '/'
    when '/ceil' then page = 'ceil';   req.url[5...] or '/'
    when '/ligh' then page = 'lights'; req.url[7...] or '/'
    when '/scro' then req.url
    else page = 'lights'; req.url[7...] or '/'  # ''
  if not req.url
    log req.url, 'not found, page:', page
    res.writeHead 404, "Content-Type": "text/plain"
    res.end req.url + ' not found, page:' + page
    return

  if req.url is '/'
    res.writeHead 200, "Content-Type": "text/html"
    res.end switch page
      when 'hvac'   then html
      when 'ceil'   then ceilHtml
      when 'lights' then lightsHtml
      else ''
    return

  if page is 'lights' and req.url[0..4] is '/ajax'
    # res.writeHead 200, "Content-Type": "text/html"
    light_cmd = JSON.parse url.parse(req.url, yes).query.json
    light_cmd.__ = seq++
    # log light_cmd
    $.light_cmd light_cmd
    res.end()
    return

  if req.url is '/ceil'
    res.writeHead 200, "Content-Type": "text/html"
    res.end ceilHtml
    # log 'ceil-req:', req.url
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
        {room, variable, setData} = data
        if variable is 'setpoint' and tstatByRoom[room]
          tstatByRoom[room].setpoint += (if setData is 'up' then +0.5 else -0.5)
          $.ws_tstat_data tstatByRoom[room]
          if room is 'master'
            masterSetpoint = tstatByRoom[room].setpoint
            writeCeil()
          for conn in connections when conn.id isnt connId and tstatByRoom[data.room]
            conn.connection.write tstatByRoom[data.room]

      when 'tstat'
        tstatByRoom[data.room] = data
        $.ws_tstat_data data
        if data.room is 'master'
          masterSetpoint = (if data.mode in ['cool', 'heat'] then data.setpoint)
          writeCeil()
        for conn in connections when conn.id isnt connId and tstatByRoom[data.room]
          conn.connection.write tstatByRoom[data.room]

      when 'reqAll'
        for room in rooms
          if tstatByRoom[room]
            tstat = tstatByRoom[room]
            connection.write tstat
            if tstat.room is 'master'
              masterSetpoint = (if tstat.mode in ['cool', 'heat'] then tstat.setpoint)
              writeCeil()
          if tempsByRoom[room] then connection.write tempsByRoom[room]
          writeCodes room

  connection.on 'end', ->
    leanConns = []
    for conn in connections
      if conn.id isnt connId
        leanConns.push conn
    connections = leanConns
