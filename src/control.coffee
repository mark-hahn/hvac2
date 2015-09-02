###
  src/control.coffee
  per room: tstat in; temp outside in; dampers and hvac out
  There is nothing timing dependent, that is all in timing.coffee
###

log     = (args...) -> console.log ' CTRL:', args...
Rx      = require 'rx'
emitSrc = new (require('events').EventEmitter)

rooms = ['tvRoom', 'kitchen', 'master', 'guest']

modes       = {tvRoom: 'off', kitchen: 'off', master:'off', guest: 'off'}
fans        = {tvRoom: off, kitchen: off, master:off, guest: off}
deltas      = {tvRoom:   0, kitchen: 0, master:0, guest: 0, \
               extAirIn: 0, freeze:  0}

lastActive  = {tvRoom: no, kitchen: no, master:no, guest: no}
lastDampers = {tvRoom: off, kitchen: off, master:off, guest: off}
lastHvac    = {extAir: off, fan: off, heat: off, cool: off}
lastThaw = no
  
check = ->
  # log 'check', airIntake, outsideTemp, modes, fans, deltas
  
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
        else lastHvac.extAir
      
    if sysMode is 'cool'
      thaw = switch
        when deltas.freeze < 0 then on
        when deltas.freeze > 0 then off
        else lastThaw
    
    sysActive = no
    if sysMode in ['heat', 'cool']
      for room in rooms when modes[room] is sysMode
        delta = deltas[room]
        sysActive or= active[room] = switch
          when sysMode is 'cool' and delta > 0 then yes
          when sysMode is 'cool' and delta < 0 then no
          when sysMode is 'heat' and delta > 0 then no
          when sysMode is 'heat' and delta < 0 then yes
          else lastActive[room]
    
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
  lastThaw = thaw

  dampersChanged = no
  for room in rooms
    if dampers[room] isnt lastDampers[room]
      dampersChanged = yes
      lastDampers[room] = dampers[room]
  if dampersChanged 
    emitSrc.emit 'dampers', dampers
      
  hvacChanged = no
  for out in ['extAir', 'fan', 'heat', 'cool']
    if hvac[out] isnt lastHvac[out]
      hvacChanged = yes
      lastHvac[out] = hvac[out]
  if hvacChanged 
    emitSrc.emit 'hvac', hvac
  
module.exports =
  init: (@obs$) -> 
    names = rooms.concat 'extAirIn', 'freeze'
    
    for name in names then do (name) =>
      @obs$['tstat_' + name + '$'].forEach (data) ->
        if name in rooms
          room = name
          {mode, fan, delta} = data
          modes[room] = mode
          fans[room]  = fan
        else
          delta = data
        deltas[name] = delta
        # log 'tstat_' + name + '$' + ' in', data  
        check()
    
    @obs$.ctrl_dampers$ = Rx.Observable.fromEvent emitSrc, 'dampers'
    @obs$.ctrl_hvac$    = Rx.Observable.fromEvent emitSrc, 'hvac'    
       
