###
  src/drivers/logging.coffee
###

{log, logObj} = require('./utils') 'LOGNG'
$ = require('imprea') 'logng'

sprintf = require('sprintf-js').sprintf
moment  = require 'moment'
_       = require 'underscore'

$.output 'log_masterCode'

fmts = ''; args = []

str = (s) -> fmts += s

ltr = (val, uc = no) ->
  fmts += '%1s'
  val = val ? '-'
  if uc then val = val.toUpperCase()
  char = val[0].replace /[Oo]/, '-'
  args.push char
  char

tmp = (val) ->
  if val 
    fmts += '%4.1f'
    args.push val 
  else
    fmts += '--.-'
    
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
fans      = {tvRoom:  off,  kitchen:  off,  master: off,  guest:  off }
modes     = {tvRoom: 'off', kitchen: 'off', master:'off', guest: 'off'}
setpoints = {tvRoom:    0,  kitchen:    0,  master:   0,  guest:    0 }

$.react '*', (name) ->
  if name is 'temp_airIntake' then return
  
  fmts = '  '; args = []
  
  ws = @allWebSocketIn ? {}
  if ws.type is 'tstat'
    fans[ws.room]      = ws.fan
    modes[ws.room]     = ws.mode
    setpoints[ws.room] = ws.setpoint
  
  fanActive =  @timing_hvac?.fan
  sysActive = (@timing_hvac?.cool or @timing_hvac?.heat)
  sysActual = switch 
    when @ctrl_thaw      then 't'
    when @timing_delayed then 'd'
    when sysActive       then @ctrl_sysMode
    when fanActive       then 'f'
    else '-'

  ltr @ctrl_sysMode
  ltr sysActual
  str ' '
  ltr (if @timing_extAirIn then 'e' else ' ')
  int @temp_airIntake
  str '-'
  int @temp_outside
  str ' '
  int @temp_acReturn, 3
  
  for room in ['tvRoom', 'kitchen', 'master', 'guest']
    damper = @timing_dampers?[room]
    
    mode   = modes[room]
    active = (mode in ['cool', 'heat'])
    if fans[room] and not active then mode = 'fan'
    
    actual = switch 
      when sysActive and damper then mode
      when fanActive and damper then 'f'
      else '-'
    
    str '  '
    ltr room, yes
    str ':'
    modeLtr   = ltr mode, (fans[room] and mode isnt 'fan')
    actualLtr = ltr actual
    str ' '
    tmp @['temp_' + room]
    str '-'
    tmp (if active then setpoints[room])
    str ' '
    
    if room is 'master'
      log 'sending @log_masterCode', modeLtr + actualLtr
      @log_masterCode? modeLtr + actualLtr
  
  line = sprintf fmts, args...
  if line isnt lastLine
    console.log moment().format('MM/DD HH:mm:ss.SS') + line
    lastLine = line
  
# 09/10 11:07:03.39 ctrl:   CCI  12 79-90   T:CC 75.35 74.75   K:CC 82.03 74.75   
#                                           M:O- 75.94 --.--   G:O- 88.36 --.--      
# type:tstat, room:tvRoom, fan:false, mode:cool, setpoint:70
