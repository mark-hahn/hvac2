###
  websocket.coffee
  http server / websocket <-> rx
###

log = (args...) -> console.log 'WSOCK:', args...

port = 4444

Rx          = require 'rx'
http      	= require 'http'
Primus      = require 'primus'
url       	= require 'url'
nodeStatic  = require 'node-static'
fileServer 	= new nodeStatic.Server '/root/apps/hvac', cache: 0

module.exports =
  init:  (@obs$) -> 
    @obs$.allWebSocketIn$ = 
      Rx.Observable.create (observer) ->
        # debug
        setTimeout ->
          observer.onNext
            type: 'tstat'
            room: 'tvRoom'
            fan:  off
            mode: 'cool'
            setPoint: 74
        , 2000
        setTimeout ->
          observer.onNext
            type: 'tstat'
            room: 'kitchen'
            fan:  on
            mode: 'cool'
            setPoint: 76
        , 4000
        
        # srvr = http.createServer (req, res) ->
        # 	console.log 'req:', req.url
        # 	req.addListener('end', ->
        # 		fileServer.serve req, res, (err) ->
        # 			if err and req.url[-4..-1] not in ['.map', '.ico']
        # 				console.log 'fileServer BAD URL:', req.url, err
        # 	).resume()
        # 
        # srvr.listen port
        # console.log 'Listening on port', port
        # 
        # primus = new Primus srvr, iknowhttpsisbetter: yes
        # primus.save 'js/primus.js'
        # 
        # primus.on 'connection', (spark) ->
        # 	console.log 'ws connection from ', spark.address
        # 
        # 	spark.on 'data', (data) ->
        # 	  console.log 'ws data', data
        #   observer.onNext data
        # 
        #     # spark.write data
        # 
