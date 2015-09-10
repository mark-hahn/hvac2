###
  src/drivers/logging.coffee
###

{log, logObj} = require('./utils') 'LOGNG'
$ = require('imprea') 'logng'

sprintf = require('sprintf-js').sprintf
moment  = require 'moment'
_       = require 'underscore'

fmts = ''; args = []

str = (s) -> fmts += s

ltr = (val) ->
  fmts += '%1s'
  args.push (val ? '-').toUpperCase()[0].replace 'O', '-'

num = (val) ->
  if val 
    fmts += '%5.1f'
    args.push val 
  else
    fmts += '--.--'
    
int = (val) ->
  if val? then str '---'
  else
    fmts += '%-3.0f'
    args.push val

lastLine = ''

modes     = {tvRoom: 'off', kitchen: 'off', master:'off', guest: 'off'}
fans      = {tvRoom:   on,  kitchen:   on,  master:  on,  guest:   on }
setpoints = {tvRoom:    0,  kitchen:    0,  master:   0,  guest:    0 }

$.react '*', (name) ->
  if name in ['temp_airIntake', 'temp_acReturn']
    return
  fmts = '   '; args = []
  
  ws = @allWebSocketIn ? {}
  if ws.type is 'tstat'
    fans[ws.room]      = ws.fan
    modes[ws.room]     = ws.mode
    setpoints[ws.room] = ws.setpoint
  
  fanActive =  @timing_hvac?.fan
  sysActive = (@timing_hvac?.cool or  @timing_hvac?.heat)
    
  ltr @ctrl_sysMode
  ltr (if not sysActive then '-' else @ctrl_sysMode)
  ltr (if @timing_extAirIn then 'E' else 'I')
  ltr '  '
  int @temp_acReturn
  str '  '
  int @temp_airIntake
  str '-'
  int @temp_outside
  
  for room in ['tvRoom', 'kitchen', 'master', 'guest']
    damper = @timing_dampers?[room]
    
    mode = modes[room]
    if fans[room] then mode = mode.toLowerCase()
    
    actual = switch 
      when sysActive and damper       then mode
      when fanActive and fans[room]   then 'F'
      when @timing_delayed and damper then 'D'
      else '-'
    
    str '   '
    ltr room
    str ':'
    ltr mode
    ltr actual
    str ' '
    num @['temp_' + room]
    str ' '
    num setpoints[room]
  
  line = sprintf fmts, args...
  if line isnt lastLine
    console.log moment().format('MM/DD HH:mm:ss.SS') + ' ' + line
    lastLine = line
  
# 09/10 11:07:03.39 ctrl:   CCI  12 79-90   T:CC 75.35 74.75   K:CC 82.03 74.75   
#                                           M:O- 75.94 --.--   G:O- 88.36 --.--      
# type:tstat, room:tvRoom, fan:false, mode:cool, setpoint:70
