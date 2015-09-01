###
  src/timing.coffee
  control(dampers/hvac) and ac-return in, timing(dampers/hvac) out
  this the timing-related code, not the control module
  goals:
    don't wear out dampers
    always have a damper open when blower on
      (freeze old damper state)
    don't start ac too often
    don't let ac freeze up
###

log     = (args...) -> console.log 'OVERR:', args...
Rx      = require 'rx'
emitSrc = new (require('events').EventEmitter)

nextChkAgainTime = 0

extAirDelay     = 10 * 60e3
minDampCyle     =       5e3
fanHold         =  2 * 60e3
lastActiveOffTime = 0
lastExtAirChgTime = 0
  
freezeTemp     = -5
thawedTemp     =  3
lastFreezeTime = 0
minThawTime    = 3 * 60e3
thawing = no

allDampersOffTime = 0
dampersOffDelay   = 10 * 60e3

lastAcOnTime = 0
minAcCyle    =  4 * 60e3

lastDamperChgTime = {}

rooms = ['tvRoom', 'kitchen', 'master', 'guest']

dampersReq   = {tvRoom: on, kitchen: on, master:on, guest: on}
lastDampers  = {tvRoom: on, kitchen: on, master:on, guest: on}
hvacReq      = {extAir: off, fan: off, heat: off, cool: off}
lastHvac     = {extAir: off, fan: off, heat: off, cool: off}
acReturnTemp = null

allRoomsEqual = (a, b) ->
  for room in rooms
    if a[room] isnt b[room] then return false
  true
  
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
    
  expired = (evtTime, delay) -> now > evtTime + delay
  lt = (a, b) -> a? and b? and a < b
  
  checkAgainAt = (time) ->
    if time > now and time < nextChkAgainTime
      nextChkAgainTime = time
      setTimeout check, time - now + 100
    
  checkAgainDelay = (delay) ->
    checkAgainAt now + delay
  
  # ac freeze
  if lt(acReturnTemp, freezeTemp)
    lastFreezeTime = now 
    thawing = yes
  else if thawing and 
    ( lt(acReturnTemp, thawedTemp) or 
      not expired lastFreezeTime, minThawTime )
    thawing = yes
  else 
    thawing = no
    lastFreezeTime = 0
  if thawing
    hvacReq.cool = off
    hvacReq.fan  = on
    if not expired lastFreezeTime, minThawTime
      checkAgainAt lastFreezeTime + minThawTime
    
  # all room dampers closed
  if allRoomsEqualTo dampersReq, off
    allDampersOffTime or= now
    if not expired allDampersOffTime, dampersOffDelay
      copyAllRoomsTo lastDampers, dampersReq
      checkAgainAt allDampersOffTime + dampersOffDelay
    else
      setAllRoomsTo dampersReq, on
  else
    allDampersOffTime = 0
    
  # ac cycling limit
  if not expired lastAcOnTime, minAcCyle
    hvacReq.cool = off
  else
    lastAcOnTime = 0
  if hvacReq.cool and not lastHvac.cool
    lastAcOnTime = now
  

module.exports =
  init: (@obs$) -> 
    
    @obs$.ctrl_dampers$.forEach (dampers) -> 
      log 'ctrl_dampers$ in', dampers
      dampersReq = dampers
      check()
        
    @obs$.ctrl_hvac$.forEach (hvac) -> 
      log 'ctrl_hvac$ in', hvac
      hvacReq = hvac
      check()
      
    @obs$.temp_acReturn$.forEach (acReturn) -> 
      log 'temp_acReturn$ in', acReturn
      acReturnTemp = acReturn
      check()
    
    @obs$.over_dampers$ = Rx.Observable.fromEvent emitSrc, 'dampers'
    @obs$.over_hvac$    = Rx.Observable.fromEvent emitSrc, 'hvac'    
       
