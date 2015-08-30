###
  src/tstat.coffee
  per room: mode and compare tsat setting to setpoint -> -1, 0, +1
###

log = (args...) -> console.log 'TSTAT:', args...

Rx      = require 'rx'
emitSrc = new (require('events').EventEmitter)

hysterisis = 0.25

rooms = ['tvRoom', 'kitchen', 'master', 'guest']

observers  = {}
modes      = {}; lastModes  = {}
fans       = {}; lastFans   = {}; lastDeltas = {}
temps      = {}
setPoints  = {}

check = (room) ->
  if not (mode = modes[room]) or
     not (temp = temps[room]) 
    return
  fan      = fans[room]
  setPoint = setPoints[room]
  delta = switch
    when temp <= setPoint - hysterisis then -1
    when temp >= setPoint + hysterisis then +1
    else 0
  if mode  isnt lastModes[room] or 
     fan   isnt lastFans[room]  or
     delta isnt lastDeltas[room]
    lastModes[room]  = mode
    lastFans[room]   = fan
    lastDeltas[room] = delta

    observers[room].onNext {mode, fan, delta}

module.exports =
  init: (@obs$) -> 
    
    @obs$.allWebSocketIn$.forEach (data) ->
      {type, room, mode, fan, setPoint} = data
      if type is 'tstat'
        # log 'newTstatSetting', {room, setPoint, mode}
        modes[room]     ?= mode
        fans[room]      ?= fan
        setPoints[room] ?= setPoint
        check room
        
    for room in rooms then do (room) =>
      @obs$['temp_' + room + '$'].forEach (temp) ->
        # log 'newTemp', {room, temp}
        temps[room] ?= temp
        check room

      @obs$['tstat_' + room + '$'] = 
        Rx.Observable.create (observer) -> 
          observers[room] = observer
      
      