###
  src/drivers/logging.coffee
###

{log, logObj} = require('./utils') 'LOGNG'

sprintf = require('sprintf-js').sprintf
moment  = require 'moment'
_       = require 'underscore'

vals = {}
fmts = ''; args = []

str = (s) -> fmts += s

ltr = (argName) ->
  fmts += '%1s'
  args.push (vals[argName] ? '-').toUpperCase()[0].replace 'O', '-'

num = (argName) ->
  fmts += '%5.1f'
  args.push vals[argName] ? 0

lastLine = ''
check = (data, name) ->
  if name
    vals[name] = data
  else
    _.extend vals, data
  args = []; fmts = '%s '; args.push moment().format('MM/DD HH:mm:ss.SS')
  ltr 'sysMode'
  str ' T:'
  num 'temp_tvRoom'
  
  line = sprintf fmts, args...
  if line isnt lastLine
    console.log line
    lastLine = line
  
module.exports =
  init: (@obs$) ->
    
    @obs$.ctrl_info$  .forEach (data) -> check data
    @obs$.temp_tvRoom$.forEach (data) -> check data, 'temp_tvRoom'
    
