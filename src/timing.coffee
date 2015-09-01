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

extAirDelay = 20 * 60e3
minAcCyle   =  4 * 60e3
minDampCyle =       5e3
fanHold     =  2 * 60e3

freezeTemp  = -5
thawedTemp  =  5
minThawTime = 3 * 60e3

lastFreezeTime = 0
lastActiveOffTime = 0
lastAcOnTime      = 0
lastExtAirChgTime = 0
lastDamperChgTime = {}

rooms = ['tvRoom', 'kitchen', 'master', 'guest']

dampersReq   = {tvRoom: off, kitchen: off, master:off, guest: off}
lastDampers  = {tvRoom: off, kitchen: off, master:off, guest: off}
hvacReq      = {extAir: off, fan: off, heat: off, cool: off}
lastHvac     = {extAir: off, fan: off, heat: off, cool: off}
acReturnTemp = null

allRoomsEqual = (a, b) ->
  for room in rooms
    if a[room] isnt b[room] then return false
  true
  
check = ->
  # log 'check', airIntake, outsideTemp, modes, fans, deltas
  
  now = Date.now()
  
  expired = (evtTime, delay) -> now > evtTime + delay
  lt = (a, b) -> a? and b? and a < b
  
  checkAgainDelay = (delay) ->
    if delay > 0 then setTimeout check, delay + 100
  
  checkAgainAt = (time) -> checkAgainDelay time - now
    
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
  if thawing then 
  
     
  
  
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
       
