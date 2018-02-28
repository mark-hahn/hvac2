###
  src/tstat.coffee
  per name: mode and compare tsat setting to setpoint -> -1, 0, +1
###

{log, logObj} = require('./log') 'TSTAT'
$ = require('imprea')()

roomHysterisis  = 0.25
extDiffHigh     =  8
extDiffLow      =  4
thawedTemp      =  5
freezeTemp      = -5

rooms = ['tvRoom', 'kitchen', 'master', 'guest']
observers  = {}
modes      = {}
fans       = {}
temps      = {}
setpoints  = {}

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
        when temp >= setpoint + roomHysterisis   then +1
        when temp <= setpoint - roomHysterisis   then -1
        else 0
      $['tstat_' + name] {mode, fan, delta}
    return

  if name in ['airIntake', 'outside']
    if temps.airIntake and temps.outside
      diff = temps.airIntake - temps.outside
      delta = switch
        when diff <= extDiffLow  then -1
        when diff >= extDiffHigh then +1
        else 0
      # log 'diff', diff, temps.outside, temps.airIntake, delta
      $.tstat_extAirIn delta
    return

  if name is 'acReturn'
    if temps.acReturn?
      delta = switch
        when temps.acReturn <= freezeTemp then -1
        when temps.acReturn >= thawedTemp then +1
        else 0
      $.tstat_freeze delta
    return

module.exports =
  init: ->
    $.react 'ws_tstat_data', ->
      {type, room, mode, fan, setpoint} = @ws_tstat_data
      modes[room]     = mode
      fans[room]      = fan
      setpoints[room] = setpoint
      check room

    names = rooms.concat 'airIntake', 'outside', 'acReturn'

    for name in names then do (name) =>
      obsName = 'temp_' + name
      $.react obsName, ->
        temps[name] = $[obsName]
        check name

      if name isnt 'airIntake'
        nameOut = switch name
          when 'outside'  then 'extAirIn'
          when 'acReturn' then 'freeze'
          else name
        $.output 'tstat_' + nameOut
