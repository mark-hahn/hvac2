
{log, logObj} = require('./utils') ' MAIN'

console.log ''

modules = [
  './xbee', 
  './wx-station'
  './temp'
  './websock-server'
  './tstat'
  './control'
  './timing'
  './insteon'
  './logging'
  './debug'
]

for module in modules 
  log 'starting', module
  require(module).init?()
  