###
  src/tstat.coffee
  per room: mode and compare tsat setting to setpoint -> -1, 0, +1
###

log = (args...) -> console.log 'TSTAT:', args...
Rx  = require 'rx'

hysterisis = 0.25
rooms = ['tvRoom', 'kitchen', 'master', 'guest']
observers  = {}
modes      = {}; lastModes  = {}
fans       = {}; lastFans   = {}; lastDeltas = {}
temps      = {}
setpoints  = {}

check = (room) ->
  # log 'check', {room, modes, temps, setpoints}
  if not (mode = modes[room]) or
     not (temp = temps[room]) 
    return
  fan      = fans[room]
  setpoint = setpoints[room]
  delta = switch
    when temp <= setpoint - hysterisis then -1
    when temp >= setpoint + hysterisis then +1
    else 0
  if mode  isnt lastModes[room] or 
     fan   isnt lastFans[room]  or
     delta isnt lastDeltas[room]
    lastModes[room]  = mode
    lastFans[room]   = fan
    lastDeltas[room] = delta

    for obs in observers[room]
      obs.onNext {mode, fan, delta}

module.exports =
  init: (@obs$) -> 
    
    @obs$.allWebSocketIn$.forEach (data) ->
      {type, room, mode, fan, setpoint} = data
      # log 'allWebSocketIn$', data
      if type is 'tstat'
        modes[room]     = mode
        fans[room]      = fan
        setpoints[room] = setpoint
        check room
        
    for room in rooms then do (room) =>
      @obs$['temp_' + room + '$'].forEach (temp) ->
        temps[room] ?= temp
        check room

      @obs$['tstat_' + room + '$'] = 
        Rx.Observable.create (observer) -> 
          observers[room] ?= []
          observers[room].push observer
      
      