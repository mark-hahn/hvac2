
moment = require 'moment'
log = (args...) -> 
  time = moment().format('MM/DD HH-mm-ss')
  console.log time, args...

util = require 'util'
Rx   = require 'rx'
xbee = require './xbee'

obsNames = [
  'wxTemp$'
  'temp_tvRoom$'
  'temp_kitchen$'
  'temp_master$'
  'temp_guest$'
  'temp_acReturn$'
  'temp_airIn$'
]

pad = (str, len) ->
  while str.length < len then str += ' '
  str
  
padPfx = (val, len, precision) ->
  if not isNaN val
    val = (+val).toFixed precision
  val = val.toString()
  while val.length < len
    val = ' ' + val
  val
  
module.exports =
  init: (@obs$) -> 
    for obsName in obsNames then do (obsName) =>
      @obs$[obsName].forEach (item) -> 
        item = padPfx item, 6, 1
        log pad(obsName,15), item.replace(/\n/g, ' ')[0..100]
