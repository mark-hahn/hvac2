###
  src/temp.coffee
  xbee packet stream -> filtered/rounded/unique temp streams for each sensor
###

log = (args...) -> console.log 'TSTAT:', args...

Rx      = require 'rx'
emitSrc = new (require('events').EventEmitter)

hysterisis = 0.25

module.exports =
  init: (@obs$) -> 
    
    @obs$.allWebSocketIn$.forEach (data) ->
      {type, room, setPoint, mode} = data
      log 'allWebSocketIn$', {type, room, setPoint, mode}
      