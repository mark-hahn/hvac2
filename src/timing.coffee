###
  src/timing.coffee
  control(dampers/hvac) in and timing(dampers/hvac) out
###

log    = (args...) -> console.log 'TIMNG:', args...
logobj = (title, obj) -> log require('./utils').fmtobj title, obj

Rx      = require 'rx'
emitSrc = new (require('events').EventEmitter)

minDampCyle     = 5e3
fanHold         = 30e3 # 2 * 60e3
extAirDelay     = 20e3 #10 * 60e3
dampersOffDelay = 120e3 #10 * 60e3
minAcOff        = 30e3 # 4 * 60e3

nextChkAgainTime  = 0
lastActiveOffTime = 0
allDampersOffTime = 0
lastAcOffTime     = 0
lastExtAirOnTime  = 0

dampersReq    = {tvRoom: on, kitchen: on, master:on, guest: on}
lastDampers   = {tvRoom: on, kitchen: on, master:on, guest: on}
dampersOnTime = {tvRoom: on, kitchen: on, master:on, guest: on}
hvacReq       = {extAir: off, fan: off, heat: off, cool: off}
lastHvac      = {extAir: off, fan: off, heat: off, cool: off}

rooms = ['tvRoom', 'kitchen', 'master', 'guest']
allRoomsEqual = (a, b) ->
  for room in rooms
    if a[room] isnt b[room] then return no
  yes
allRoomsEqualTo = (a, b) ->
  for room in rooms
    if a[room] isnt b then return no
  yes
setAllRoomsTo = (a, b) ->
  for room in rooms then a[room] = b
copyAllRoomsTo = (a,b) ->
  for room in rooms then b[room] = a[room]
    
hvacs = ['extAir', 'fan', 'heat', 'cool']
allHvacsEqual = (a, b) ->
  for hvac in hvacs
    if a[hvac] isnt b[hvac] then return no
  yes
copyAllHvacsTo = (a,b) ->
  for hvac in hvacs then b[hvac] = a[hvac]
    
check = ->
  now = Date.now()
  if now > nextChkAgainTime
    nextChkAgainTime = 0
    
  checkAgainAt = (time) ->
    if time > now and time < nextChkAgainTime
      nextChkAgainTime = time
      setTimeout check, time - now + 100
    
  expired = (evtTime, delay) -> 
    exp = now > evtTime + delay
    if not exp then checkAgainAt evtTime + delay
    exp
    
  # all room dampers closed
  if allRoomsEqualTo dampersReq, off
    allDampersOffTime or= now
    if not expired allDampersOffTime, dampersOffDelay
      copyAllRoomsTo lastDampers, dampersReq
    else
      setAllRoomsTo dampersReq, on
      
  # any damper cycle limit
  for room in rooms
    if not lastDampers[room] and dampersReq[room]
      dampersOnTime[room] = now
    if not expired dampersOnTime[room], minDampCyle
      dampersReq[room] = on
    
  # ac cycling limit
  if lastHvac.cool and not hvacReq.cool
    lastAcOffTime = now
  if not expired lastAcOffTime, minAcOff
    hvacReq.cool = off
    
  # extAirIn cycling limit
  if not lastHvac.extAir and hvacReq.extAir
    lastExtAirOnTime = now
  if not expired lastExtAirOnTime, extAirDelay
    hvacReq.extAir = on
    
  # min fan on after active off
  active     = ( hvacReq.heat or  hvacReq.cool)
  lastActive = (lastHvac.heat or lastHvac.cool)
  if lastActive and not active
    lastActiveOffTime = now
  if not expired lastActiveOffTime, fanHold
    hvacReq.fan = yes

  if not allRoomsEqual dampersReq, lastDampers
    # logobj 'damp out', dampersReq
    emitSrc.emit 'dampers', dampersReq
    copyAllRoomsTo dampersReq, lastDampers

  if not allHvacsEqual hvacReq, lastHvac
    # logobj 'hvac out', hvacReq
    emitSrc.emit 'hvac', hvacReq
    copyAllHvacsTo hvacReq, lastHvac
    
module.exports =
  init: (@obs$) -> 
    
    @obs$.ctrl_dampers$.forEach (dampers) -> 
      # logobj 'damp in', dampers
      dampersReq = dampers
      check()
        
    @obs$.ctrl_hvac$.forEach (hvac) -> 
      # logobj 'hvac in', hvac
      hvacReq = hvac
      check()
      
    @obs$.timing_dampers$ = Rx.Observable.fromEvent emitSrc, 'dampers'
    @obs$.timing_hvac$    = Rx.Observable.fromEvent emitSrc, 'hvac'    
       
