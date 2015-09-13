###
  src/timing.coffee
  control(dampers/hvac) in and timing(dampers/hvac) out
###

{log, logObj} = require('./utils') 'TIMNG'

rooms = ['tvRoom', 'kitchen', 'master', 'guest']
hvacs = ['extAir', 'fan', 'heat', 'cool']

$ = require('imprea') 'timng'
$.output 'timing_dampers', 'timing_hvac', 'timing_extAirIn'
for room in rooms then $.output "acDelay_#{room}"

minDampCyle     =       5e3
fanHold         =  2 * 60e3
extAirDelay     = 10 * 60e3
dampersOffDelay = 10 * 60e3
minAcOff        =  4 * 60e3  

nextChkAgainTime  = Infinity
allDampersOffTime = null
lastActiveOffTime = 0
lastAcOffTime     = 0
lastExtAirOnTime  = 0

modes         = {}
dampersReq    = {tvRoom: on, kitchen: on, master:on, guest: on}
lastDampers   = {tvRoom: on, kitchen: on, master:on, guest: on}
dampersOnTime = {tvRoom:  0, kitchen:  0, master: 0, guest:  0}
hvacReq       = {extAir: off, fan: off, heat: off, cool: off}
lastHvac      = {extAir: off, fan: off, heat: off, cool: off}

allRoomsEqualTo = (a, b) ->
  for room in rooms
    if a[room] isnt b then return no
  yes
setAllRoomsTo = (a, b) ->
  for room in rooms then a[room] = b
copyAllRoomsTo = (a,b) ->
  for room in rooms then b[room] = a[room]
allHvacsEqual = (a, b) ->
  for hvac in hvacs
    if a[hvac] isnt b[hvac] then return no
  yes
copyAllHvacsTo = (a,b) ->
  for hvac in hvacs then b[hvac] = a[hvac]

pendingChecks = []
     
check = ->
  now = Date.now()
  
  chks = []
  for pendingCheck in pendingChecks
    if pendingCheck[0] <= now then clearTimeout pendingCheck[1]
    else chks.push pendingCheck
  pendingChecks = chks
  
  dampers = {}
  hvac    = {}
  copyAllRoomsTo dampersReq, dampers
  copyAllHvacsTo hvacReq,    hvac
    
  checkAgainAt = (time) ->
    if time > now
      TO = setTimeout check, time - now
      pendingChecks.push [time, TO]
      
  expired = (evtTime, delay) -> 
    exp = now > evtTime + delay
    if not exp then checkAgainAt evtTime + delay + 100
    exp
    
  # all room dampers closed
  if allRoomsEqualTo dampers, off
    allDampersOffTime ?= now
    if not expired allDampersOffTime, dampersOffDelay
      copyAllRoomsTo lastDampers, dampers
    else
      setAllRoomsTo dampers, on
  else allDampersOffTime = null
    
  # ac cycling limit
  delaying = no
  if lastHvac.cool and not hvac.cool
    lastAcOffTime = now
  if not expired lastAcOffTime, minAcOff
    hvac.cool = off
    delaying = yes
    
  for room in rooms
    $["acDelay_#{room}"] delaying and dampers[room] and 
                         modes[room] in ['heat', 'cool']
    
  # any damper cycle limit
  for room in rooms
    if not lastDampers[room] and dampers[room]
      dampersOnTime[room] = now
    if not expired dampersOnTime[room], minDampCyle
      dampers[room] = on
    
  # extAirIn cycling limit
  extAirIn = off
  if not lastHvac.extAir and hvac.extAir
    lastExtAirOnTime = now
  if not expired lastExtAirOnTime, extAirDelay
    hvac.extAir = extAirIn = on
  $.timing_extAirIn extAirIn
  
  # min fan on after active off
  active     = ( hvac.heat or  hvac.cool)
  lastActive = (lastHvac.heat or lastHvac.cool)
  if lastActive and not active
    lastActiveOffTime = now
  if not expired lastActiveOffTime, fanHold
    hvac.fan = yes

  $.timing_dampers dampers
  copyAllRoomsTo dampers, lastDampers

  $.timing_hvac hvac
  copyAllHvacsTo hvac, lastHvac
    
module.exports =
  init: -> 
    $.react 'ctrl_dampers', 'ctrl_hvac', ->
      if @ctrl_dampers and @ctrl_hvac
        dampersReq = @ctrl_dampers
        hvacReq = @ctrl_hvac
        check()
        
    $.react 'allWebSocketIn', ->
      if @allWebSocketIn.type is 'tstat'
        modes[@allWebSocketIn.room] = @allWebSocketIn.mode
        check()

      
