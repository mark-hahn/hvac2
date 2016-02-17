###
  src/timing.coffee
  control(dampers/hvac) in and timing(dampers/hvac) out
###

{log, logObj} = require('./log') 'TIMNG'

rooms = ['tvRoom', 'kitchen', 'master', 'guest']
hvacs = ['extAir', 'fan', 'heat', 'cool']

$ = require('imprea')()
$.output 'timing_dampers', 'timing_hvac', 'timing_extAirIn'

minDampCyle     =       5e3
minAcOff        =  4 * 60e3  
extAirDelay     = 10 * 60e3
dampersOffDelay = 10 * 60e3

nextChkAgainTime  = Infinity
allDampersOffTime = null
lastActiveOffTime = 0
lastAcOffTime     = 0
lastExtAirOnTime  = 0

modes  = {}
qcs    = {}

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
  
  checkAgainAt = (time) ->
    if time > now
      TO = setTimeout check, time - now
      pendingChecks.push [time, TO]
      
  expired = (evtTime, delay) -> 
    exp = now > evtTime + delay
    if not exp then checkAgainAt evtTime + delay + 100
    exp
    
  dampers = {}
  hvac    = {}
  copyAllRoomsTo dampersReq, dampers
  copyAllHvacsTo hvacReq,    hvac
    
  # ac cycling limit
  if lastHvac.cool and not hvac.cool
    lastAcOffTime = now
  if not expired lastAcOffTime, minAcOff
    hvac.cool = off
    
  # extAirIn cycling limit
  extAirIn = off
  if not lastHvac.extAir and hvac.extAir
    lastExtAirOnTime = now
  if not expired lastExtAirOnTime, extAirDelay
    hvac.extAir = extAirIn = on
  $.timing_extAirIn extAirIn

  # all room dampers closed
  if allRoomsEqualTo dampers, off
    allDampersOffTime ?= now
    if not expired allDampersOffTime, dampersOffDelay
      # fan may still be running
      copyAllRoomsTo lastDampers, dampers
      for room in rooms when qcs[room]
        dampers[room] = off
      if allRoomsEqualTo dampers, off
        dampers.master = on
    else
      setAllRoomsTo dampers, on
  else allDampersOffTime = null
  
  # any damper cycle limit
  for room in rooms
    if not lastDampers[room] and dampers[room]
      dampersOnTime[room] = now
    if not expired dampersOnTime[room], minDampCyle
      dampers[room] = on
    
  # enforce quiet control
  for r in rooms when dampers[r] and qcs[r]
    savedDampers = {}
    copyAllRoomsTo dampers, savedDampers
    loop 
      numOfVentsOpen = 0
      for room in rooms when dampers[room]
        numOfVentsOpen += (if room is 'tvRoom' then 3 else 1)
      if numOfVentsOpen >= 3 then break
      if      not dampers.tvRoom   and not qcs.tvRoom  then dampers.tvRoom  = on
      else if not dampers.master   and not qcs.master  then dampers.master  = on
      else if not dampers.guest    and not qcs.guest   then dampers.guest   = on
      else if not dampers.kitchen  and not qcs.kitchen then dampers.kitchen = on
      else 
        copyAllRoomsTo savedDampers, dampers
        dampers.tvRoom = on
    break

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
        
    $.react 'ws_tstat_data', ->
      ws = @ws_tstat_data
      modes[ws.room]  = ws.mode
      qcs[ws.room]    = ws.qc
      check()

      
