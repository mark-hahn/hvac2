
moment = require 'moment'
log = (args...) -> 
  time = moment().format('MM-DD HH:mm:ss')
  console.log time, args...

util = require 'util'
Rx   = require 'rx'

obsNames = [
  'temp_tvRoom$'
  # 'temp_kitchen$'
  # 'temp_master$'
  # 'temp_guest$'
  # 'temp_acReturn$'
  # 'temp_airIntake$'
  'allWebSocketIn$'
  # 'wxStation$'
  # 'temp_outside$'
  'tstat_tvRoom$'
  # 'tstat_kitchen$'
  # 'tstat_master$'
  # 'tstat_guest$'
  'ctrl_dampers$'
  'ctrl_hvac$'
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
        log pad(obsName,15), 
          padPfx(item)
            .replace /['"{}\s\n]/g, ''
            .replace(/,/g, ', ')[0..100]
        
