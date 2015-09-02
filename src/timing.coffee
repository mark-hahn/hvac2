###
  src/timing.coffee
  control(dampers/hvac) in and timing(dampers/hvac) out
###

log     = (args...) -> console.log 'TIMNG:', args...
Rx      = require 'rx'
emitSrc = new (require('events').EventEmitter)

minDampCyle     = 5e3
fanHold         = 30e3 # 2 * 60e3
extAirDelay     = 20e3 #10 * 60e3
dampersOffDelay = 30e3 #10 * 60e3
minAcOff        = 40e3 # 4 * 60e3

nextChkAgainTime  = 0
lastActiveOffTime = 0
allDampersOffTime = 0
lastAcOffTime     = 0

lastActive        = no

dampersReq    = {tvRoom: on, kitchen: on, master:on, guest: on}
lastDampers   = {tvRoom: on, kitchen: on, master:on, guest: on}
dampersOnTime = {tvRoom: on, kitchen: on, master:on, guest: on}
hvacReq       = {extAir: off, fan: off, heat: off, cool: off}
lastHvac      = {extAir: off, fan: off, heat: off, cool: off}

rooms = ['tvRoom', 'kitchen', 'master', 'guest']
allRoomsEqualTo = (a, b) ->
  for room in rooms
    if a[room] isnt b then return false
  true
setAllRoomsTo = (a, b) ->
  for room in rooms
    a[room] = b
  true
copyAllRoomsTo = (a,b) ->
  for room in rooms
    b[room] = a[room]
  
check = ->
  # log 'check', airIntake, outsideTemp, modes, fans, deltas
  
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
    if not expired dampersOnTime[room], minDampCyle
      dampers[room] = on
    if not lastDampers[room] and dampers[room]
      dampersOnTime[room] = now
    
  # ac cycling limit
  if not expired lastAcOffTime, minAcOff
    hvacReq.cool = off
  if lastHvac.cool and not hvacReq.cool
    lastAcOffTime = now

  # extAirIn cycling limit
  if not expired lastExtAirOnTime, extAirDelay
    hvacReq.extAir = on
  if not lastHvac.extAir and hvacReq.extAir
    lastExtAirOnTime = now
    
  # min fan on after active off
  active = (hvacReq.heat or hvacReq.cool)
  if not expired lastActiveOffTime, fanHold
    hvacReq.fan = yes
  if lastActive and not active
    lastActiveOffTime = now
  lastActive = active  
    
module.exports =
  init: (@obs$) -> 
    
    @obs$.ctrl_dampers$.forEach (dampers) -> 
      # log 'ctrl_dampers$ in', dampers
      dampersReq = dampers
      check()
        
    @obs$.ctrl_hvac$.forEach (hvac) -> 
      # log 'ctrl_hvac$ in', hvac
      hvacReq = hvac
      check()
      
    @obs$.timng_dampers$ = Rx.Observable.fromEvent emitSrc, 'dampers'
    @obs$.timng_hvac$    = Rx.Observable.fromEvent emitSrc, 'hvac'    
       
