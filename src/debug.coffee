
$      = require('imprea') 'debug'
util   = require 'util'

{log, logObj} = require('./utils') '     '

util = require 'util'

obsNames = [
  'allXbeePackets'
  'temp_outside'
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
  # 'allWebSocketIn'
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
  'timing_extAirIn'
  'timing_dampers'
  'timing_hvac'
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
    if name not in obsNames
      log pad(name, 15), 
        padPfx(value)
          .replace /['"{}\s\n]/g, ''
          .replace(/,/g, ', ')[0..100]

