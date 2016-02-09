###
  src/drivers/logging.coffee
###

{log, logObj} = require('./log') 'LOGNG'
$ = require('imprea')()

sprintf = require('sprintf-js').sprintf
moment  = require 'moment'
_       = require 'underscore'

rooms = ['tvRoom', 'kitchen', 'master', 'guest']
setpoints = {}

$.output 'log_sysMode', 'log_modeCode_sys', 'log_extAirCode', 'log_counts'
for room in rooms
  $.output 'log_modeCode_'    + room, 'log_reqCode_' + room, 'log_actualCode_' + room,
           'log_elapsedCode_' + room
  
fmts = args = null
lastActive = {}
now = Date.now()
lastActiveChg  = tvRoom: now, kitchen: now, master: now, guest: now
elapsedMins     = tvRoom:   0, kitchen:   0, master:   0, guest:   0
lastElapsedMins = tvRoom:   0, kitchen:   0, master:   0, guest:   0
  
str = (s) -> fmts += s

ltr = (val, uc = no) ->
  fmts += '%1s'
  val = val or '-'
  val = if uc then val.toUpperCase() else val.toLowerCase()
  char = val[0]
  args.push char
  char

tmp = (val) ->
  if val 
    fmts += '%4.1f'
    args.push val 
  else
    fmts += '----'
    
int = (val, wid = 2) ->
  if not val?
    dashes = ''
    for i in [0...wid] then dashes += '-'
    str dashes
  else
    fmt = "%#{wid}d"
    fmts += fmt
    args.push val

lastLine  = ''

$.react '*', (name) ->
  if name is 'temp_airIntake' then return
  
  if (ws = @ws_tstat_data) then setpoints[ws.room] = ws.setpoint

  fmts = '  '; args = []
  
  $.log_modeCode_sys modeCode_sys = 
    switch
      when @ctrl_thaw         then 'T'
      when @timing_hvac?.heat then 'H'
      when @timing_hvac?.cool then 'C'
      when @timing_hvac?.fan  then 'F'
      else                         '-'
      
  $.log_extAirCode extAirCode = (if @timing_extAirIn then 'E' else 'R')
    
  $.log_sysMode ltr (if @ctrl_sysMode isnt 'off' then @ctrl_sysMode), yes
  ltr modeCode_sys,  yes
  str ' '
  ltr extAirCode
  int @temp_airIntake
  str '-'
  int @weewx_data?.outTemp
  str ' '
  int @temp_acReturn, 3
  
  sysActive = $.timing_hvac?.cool or $.timing_hvac?.heat
  
  roomCountNotOff = 0
  roomCountActive = 0
  
  for room in rooms
    tstat       = @['tstat_' + room] ? mode: 'off', fan: off, delta: 0
    fan         = tstat.fan
    mode        = tstat.mode or 'off'
    tstatActive = mode in ['heat', 'cool']
    
    $['log_modeCode_'+room] tstatModeCode = 
      switch
        when mode is 'heat' and fan then 'U'
        when mode is 'heat'         then 'H'
        when mode is 'cool' and fan then 'Q'
        when mode is 'cool'         then 'C'
        when fan                    then 'F'
        else                             '-'
    
    $['log_reqCode_' + room] tstatReqCode = 
      switch tstatActive and tstat.delta
        when off then '-'
        when  +1 then 'v'
        when   0 then '='
        when  -1 then '^'
    
    damper = @timing_dampers?[room]
    active = sysActive and damper
    
    if mode isnt 'off' then roomCountNotOff++
    if active          then roomCountActive++
    
    $['log_actualCode_' + room] tstatActualCode =
      switch 
        when active then '@'
        when damper then 'O'
        else             '-'
          
    now = Date.now()
    elapsedMins = (now - lastActiveChg[room]) / (60*1e3)
    if active isnt lastActive[room]
      if elapsedMins >= 0.2
        lastElapsedMins[room] = elapsedMins
      elapsedMins = 0
      lastActiveChg[room] = now
      lastActive[room] = active
    if elapsedMins < 0.5 then elapsedMins = lastElapsedMins[room]
    $['log_elapsedCode_' + room] \
      (if elapsedMins < 100 then elapsedMins.toFixed 1 else Math.round elapsedMins)

    str '  '
    ltr room, yes
    str ':'
    ltr tstatModeCode
    ltr tstatReqCode
    ltr tstatActualCode
    str ' '
    tmp @['temp_' + room]
    str '-'
    tmp (if tstatActive then setpoints[room])
    str ' '
    
  $.log_counts '' + roomCountNotOff + roomCountActive
  
  line = sprintf fmts, args...
  if line isnt lastLine
    console.log moment().format('MM/DD HH:mm:ss.SS') + line
    lastLine = line
  
# 09/10 11:07:03.39 ctrl:   CCI  12 79-90   T:CC 75.35 74.75   K:CC 82.03 74.75   
#                                           M:O- 75.94 --.--   G:O- 88.36 --.--      
# type:tstat, room:tvRoom, fan:false, mode:cool, setpoint:70
