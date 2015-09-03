
moment = require 'moment'
log = (args...) -> 
  time = moment().format('MM-DD HH:mm:ss')
  # console.log time, args...
  console.log args...

util = require 'util'
Rx   = require 'rx'

obsNames = [
  'temp_outside$'
  'temp_tvRoom$'
  'temp_kitchen$'
  'temp_master$'
  'temp_guest$'
  'temp_airIntake$'
  'temp_acReturn$'
  
  'allWebSocketIn$'
  
  'tstat_tvRoom$'
  'tstat_kitchen$'
  'tstat_master$'
  'tstat_guest$'
  'tstat_extAirIn$'
  'tstat_freeze$'
  
  'ctrl_dampers$'
  'ctrl_hvac$'
  
  'timing_dampers$'
  'timing_hvac$'
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
  init: (@obs$) -> 
    for obsName in obsNames then do (obsName) =>
      @obs$[obsName].forEach (item) -> 
        log 'OBSRV:', pad(obsName,15), 
          padPfx(item)
            .replace /['"{}\s\n]/g, ''
            .replace(/,/g, ', ')[0..100]
        
