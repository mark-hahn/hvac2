###
  websocket.coffee
  http server / websocket <-> rx
###

{log, logObj} = require('./utils') 'WSOCK'

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
  masterCode = 
    $.log_modeCode_master + $.log_reqCode_master + $.log_actualCode_master + ' ' +
    $.log_elapsedCode_master
  sysCode =  
    $.log_modeCode_sys + $.log_extAirCode + $.log_counts + ''
  for conn in connections
    conn.connection.write 
      type:          'ceil'
      master:         $.temp_master?.toFixed(1) ? '----'
      masterSetpoint: (if masterSetpoint then masterSetpoint.toFixed 1 else '----')
      masterCode:     masterCode.toUpperCase().replace 'V', 'v'
      outside:   '' + Math.round $.temp_outside ? '0'
      sysCode:        sysCode.toUpperCase()

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
            'temp_outside', 
            'log_sysMode', 'log_modeCode_sys', 'log_extAirCode', 
            'log_counts', writeCeil
            
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
    console.log 'ceil-req:', req.url
    return
  
  if req.url[0..5] is '/usage'
    label = req.url[7...] or 'Oct'
    res.writeHead 200, "Content-Type": "image/svg+xml"
    res.end fs.readFileSync '/root/apps/hvac/stats/hvac-' + label + '.svg', 'utf8'
    console.log 'usage-req:', req.url
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
    
