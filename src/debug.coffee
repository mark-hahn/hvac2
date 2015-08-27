
log = (args...) -> console.log 'DEBUG:', args...

Rx = require 'rx'

exports.setAllObservables = (allObservables) -> 
  {xbeePackets$} = allObservables
  
  xbeePackets$.forEach (packet) ->
    console.log {packet}
    