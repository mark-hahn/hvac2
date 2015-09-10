###
  src/control.coffee
  per room: tstat in; temp outside in; dampers and hvac out
  There is nothing timing dependent, that is all in timing.coffee
###

{log, logObj} = require('./utils') ' CTRL'

$ = require('imprea') 'ctrl'
_ = require 'underscore'

rooms = ['tvRoom', 'kitchen', 'master', 'guest']

modes       = {tvRoom: 'off', kitchen: 'off', master:'off', guest: 'off'}
fans        = {tvRoom:   on,  kitchen:   on,  master:  on,  guest:   on }
deltas      = {tvRoom:    0,  kitchen:    0,  master:   0,  guest:    0,\
               extAirIn:  0,  freeze:     0}

lastActive  = {tvRoom: no, kitchen: no, master:no, guest: no}
lastExtAir  = off
lastThaw    = no

sysMode = 'O'

$.output 'ctrl_dampers', 'ctrl_hvac', 'ctrl_sysMode', 'ctrl_thaw'
      
check = ->
  fanCount = heatCount = coolCount = 0
  for room in rooms
    switch modes[room]
      when 'fan'  then fanCount++
      when 'heat' then heatCount++
      when 'cool' then coolCount++
  sysMode = switch
    when heatCount > coolCount then 'heat'
    when coolCount             then 'cool'
    when fanCount              then 'fan'
    else                            'off'
  
  $.ctrl_sysMode sysMode
      
  # damper on means air is flowing
  dampers = {tvRoom: off, kitchen: off, master: off, guest: off}
  hvac    = {extAir: off, fan: off,     heat: off,   cool: off}
  active  = {tvRoom: no,  kitchen: no,  master: no,  guest: no}
  thaw    = no
  
  if sysMode isnt 'off'
    
    if sysMode in ['fan', 'cool']
      hvac.extAir = switch
        when deltas.extAirIn > 0 then on
        when deltas.extAirIn < 0 then off
        else lastExtAir
    
    if sysMode is 'cool'
      thaw = switch
        when deltas.freeze < 0 then on
        when deltas.freeze > 0 then off
        else lastThaw
    $.ctrl_thaw thaw
    
    sysActive = no
    if sysMode in ['heat', 'cool']
      for room in rooms when modes[room] is sysMode
        delta = deltas[room]
        active[room] = switch
            when sysMode is 'cool' and delta > 0 then yes
            when sysMode is 'cool' and delta < 0 then  no
            when sysMode is 'heat' and delta > 0 then  no
            when sysMode is 'heat' and delta < 0 then yes
            else lastActive[room]
        sysActive or= active[room]
    
    if sysActive  
      hvac[sysMode] = on
      for room in rooms 
        if modes[room] is sysMode and deltas[room] is 0 
          active[room] = yes        
        if active[room] then dampers[room] = on
    else 
      for room in rooms when fans[room]
        hvac.fan = on 
        dampers[room] = on
        
    if thaw
      hvac.cool = hvac.heat = off
      hvac.fan  = on
      
  for room in rooms
    lastActive[room] = active[room]
  lastExtAir = hvac.extAir
  lastThaw   = thaw

  $.ctrl_dampers dampers
  $.ctrl_hvac hvac
  
module.exports =
  init: -> 
    names = rooms.concat 'extAirIn', 'freeze'
    
    for name in names then do (name) =>
      obsName = 'tstat_' + name
      $.react obsName, ->
        if name in rooms
          room = name
          {mode, fan, delta} = @[obsName]
          modes[room] = mode
          fans[room]  = fan
        else
          delta = @[obsName]
        deltas[name] = delta
        # logObj 'name in' + name + '$' + ' in', data  
        check()
    
