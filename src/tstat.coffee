###
  src/tstat.coffee
  per name: mode and compare tsat setting to setpoint -> -1, 0, +1
###

log = (args...) -> console.log 'TSTAT:', args...
Rx  = require 'rx'

roomHysterisis  = 0.25
extDiffHigh     = 6
extDiffLow      = 3
freezeTemp      = -5
thawedTemp      =  3

rooms = ['tvRoom', 'kitchen', 'master', 'guest']
observers  = {}
modes      = {}; lastModes  = {}
fans       = {}; lastFans   = {}; lastDeltas = {}
temps      = {}
setpoints  = {}

lastExtAirInDelta = lastFreezeDelta = null

check = (name) ->
  # log 'check', {name, modes, temps, setpoints}
  
  if name in rooms
    room     = name
    mode     = modes[room]
    temp     = temps[room]
    fan      = fans[room]
    setpoint = setpoints[room]
    if temp and setpoint
      delta = switch
        when temp <= setpoint - roomHysterisis then -1
        when temp >= setpoint + roomHysterisis then +1
        else 0
      if mode  isnt lastModes[room] or 
         fan   isnt lastFans[room]  or
         delta isnt lastDeltas[room]
        lastModes[room]  = mode
        lastFans[room]   = fan
        lastDeltas[room] = delta
        for obs in observers[room]
          obs.onNext {mode, fan, delta}
    return
        
  if name in ['airIntake', 'outside'] 
    if temps.outside and temps.airIntake
      diff = temps.outside - temps.airIntake
      delta = switch
        when diff <= extDiffLow  then -1
        when diff >= extDiffHigh then +1
        else 0
      if delta isnt lastExtAirInDelta
        for obs in observers.extAirIn
          obs.onNext delta
          lastExtAirInDelta = delta
    return
    
  if name is 'acReturn'
    if temps.acReturn?
      delta = switch
        when temps.acReturn <= freezeTemp then -1
        when temps.acReturn >= thawedTemp then +1
        else 0
      if delta isnt lastFreezeDelta
        for obs in observers.freeze
          obs.onNext delta
        lastFreezeDelta = delta
    return
    
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
        
    names = rooms.concat 'airIntake', 'outside', 'acReturn'
    
    for name in names then do (name) =>
      log name
      @obs$['temp_' + name + '$'].forEach (temp) ->
        temps[name] ?= temp
        check name
        
      switch name
        when 'airIntake' then return
        when 'outside'   then name = 'extAirIn' 
        when 'acReturn'  then name = 'freeze'

      @obs$['tstat_' + name + '$'] = 
        Rx.Observable.create (observer) -> 
          observers[name] ?= []
          observers[name].push observer      
          
