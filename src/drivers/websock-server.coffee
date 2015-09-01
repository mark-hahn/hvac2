###
  websocket.coffee
  http server / websocket <-> rx
###

log = (args...) -> console.log 'WSOCK:', args...

port = 4444

Rx          = require 'rx'
http        = require 'http'
Primus      = require 'primus'
url         = require 'url'
nodeStatic  = require 'node-static'
html        = require('../www/js/index-html')()
fileServer  = new nodeStatic.Server 'www', cache: 0
  
observers   = []
connections = [] 

rooms = ['tvRoom', 'kitchen', 'master', 'guest']
tempsByRoom = {}
tstatByRoom = {}

module.exports =
  init:  (@obs$) -> 
    @obs$.allWebSocketIn$ = 
      Rx.Observable.create (observer) -> 
        observers.push observer
        
    for room in rooms then do (room) =>
      @obs$['temp_' + room + '$'].forEach (temp) ->
        # log 'recvd temp', temp, connections.length
        tempData = {type: 'temp', room, temp}
        tempsByRoom[room] = tempData
        for conn in connections
          conn.connection.write tempData
        null
    null
      
srvr = http.createServer (req, res) ->
  # log 'req:', req.url
  
  if req.url is '/'
    res.writeHead 200, "Content-Type": "text/html"
    res.end html
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
  log 'new connection', connection.address
  # log 'new connection', {id: connId, connections, addr: connection.address}
  
  connection.on 'data', (data) ->
    # log 'connection.on data', data
    
    for obs in observers
      switch data.type
        
        when 'tstat' 
          obs.onNext data
          tstatByRoom[data.room] = data
          for conn in connections when conn.id isnt connId and tstatByRoom[data.room]
            conn.connection.write tstatByRoom[data.room]
          null
          
        when 'reqAll'
          for room in rooms
            if tstatByRoom[room]
              connection.write tstatByRoom[room]
            if tempsByRoom[room]
              connection.write tempsByRoom[room]
          null
    null
            
  connection.on 'end', ->
    leanConns = []
    for conn in connections
      if conn.id isnt connId
        leanConns.push conn
    connections = leanConns
    
