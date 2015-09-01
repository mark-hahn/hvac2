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
  
observers = []

module.exports =
  init:  (@obs$) -> 
    @obs$.allWebSocketIn$ = 
      Rx.Observable.create (observer) -> 
        observers.push observer
        
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

primus.on 'connection', (spark) ->
  log 'connection from ', spark.address

  spark.on 'data', (data) ->
    # log 'spark.on data', data
    for obs in observers
      obs.onNext data
    
      # spark.write data
    
