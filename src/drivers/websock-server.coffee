###
  websocket.coffee
  http server / websocket <-> rx
###

{log, logObj} = require('./utils') 'WSOCK'
scroll = require '../js/scroll'

port = 1339

fs          = require 'fs'
$           = require('imprea')()
http        = require 'http'
Primus      = require 'primus'
url         = require 'url'
nodeStatic  = require 'node-static'
html        = require('../www/js/index-html')()
ceilHtml    = require('../www/js/ceil-html')()
moment      = require 'moment'
fileServer  = new nodeStatic.Server 'www', cache: 0
connections = [] 

rooms = ['tvRoom', 'kitchen', 'master', 'guest']
tempsByRoom = {}
tstatByRoom = {}

$.output 'ws_tstat_data'

masterSetpoint = null

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
          
    $.react 'temp_master', 
            'log_modeCode_master', 'log_reqCode_master', 'log_actualCode_master',
            'log_elapsedCode_master', 
            'log_sysMode', 'log_modeCode_sys', 'log_extAirCode', 
            'weewx_data', 'log_counts', writeCeil
            
    for room in rooms then do (room) ->
      $.react 'log_modeCode_sys', 'log_extAirCode',
              'log_reqCode_' + room, 'log_actualCode_' + room
      , -> writeCodes room

srvr = http.createServer (req, res) ->
  log 'req:', req.url
  
  if req.url is '/'
    res.writeHead 200, "Content-Type": "text/html"
    res.end html
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
    # try
      # file = '/root/apps/hvac/stats/hvac-scroll.svg'
    res.writeHead 200, "Content-Type": "image/svg+xml"
    scroll +timespan, (data) ->
      res.end data, 'utf8'
    # catch e
    #   log 'scroll read error:', file, e
    #   res.writeHead 500, "Content-Type": "text/plain"
    #   res.end 'Scroll file read error: ' + file + ', ' +JSON.stringify e
    return
  
  req.addListener('end', ->
    fileServer.serve req, res, (err) ->
      if err and req.url[-4..-1] not in ['.map', '.ico']
        log 'BAD URL:', req.url, err
  ).resume()

srvr.listen port
log 'Listening on port', port

primus = new Primus srvr, iknowhttpsisbetter: yes
primus.save 'www/js/primus.js'

primus.on 'connection', (connection) ->
  connId = connection.id.split('$')[0]
  connections.push {id: connId, connection}
  
  connection.on 'data', (data) ->
    # log 'connection.on data', data
    
    switch data.type
      when 'tstat' 
        $.ws_tstat_data data
        tstatByRoom[data.room] = data
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
    
