
$      = require('imprea')()
util   = require 'util'

{log, logObj} = require('./log') '     '

dontShow = [
  'allXbeePackets'
  'temp_outside'
  'inst_remote'
  'light_cmd'
  'xbeePacket_tvRoom'
  'xbeePacket_kitchen'
  'xbeePacket_master'
  'xbeePacket_guest'
  'xbeePacket_closet'
  'temp_tvRoom'
  'temp_kitchen'
  'temp_master'
  'temp_guest'
  'temp_acReturn'
  'temp_airIntake'
  'ws_tstat_data'
  'tstat_tvRoom'
  'tstat_kitchen'
  'tstat_master'
  'tstat_guest'
  'tstat_extAirIn'
  'tstat_freeze'
  'ctrl_sysMode'
  'ctrl_info'
  'ctrl_dampers'
  'ctrl_hvac'
  'ctrl_thaw'
  'timing_hvac'
  'timing_dampers'
  'timing_acDelay'
  'timing_extAirIn'
  'log_modeCode_sys'
  'log_extAirCode'
  'log_modeCode_tvRoom'
  'log_modeCode_kitchen'
  'log_modeCode_master'
  'log_modeCode_guest'
  'log_reqCode_tvRoom'
  'log_reqCode_kitchen'
  'log_reqCode_master'
  'log_reqCode_guest'
  'log_actualCode_tvRoom'
  'log_actualCode_kitchen'
  'log_actualCode_master'
  'log_actualCode_guest'
  'log_elapsedCode_tvRoom'
  'log_elapsedCode_kitchen'
  'log_elapsedCode_master'
  'log_elapsedCode_guest'
  'log_counts'
  'log_sysMode'
  'weewx_data'
]

pad = (str, len) ->
  while str.length < len then str += ' '
  str
  
padPfx = (val, len, precision = 1) ->
  if typeof val is 'number'
    val = val.toFixed precision
    while val.length < len
      val = ' ' + val
  else
    val = util.inspect val, depth: null
  val
  
module.exports =
  $.react '*', (name, value) ->
    if name not in dontShow
      log pad(name, 15), 
        padPfx(value)
          .replace /['"{}\s\n]/g, ''
          .replace(/,/g, ', ')[0..100]

