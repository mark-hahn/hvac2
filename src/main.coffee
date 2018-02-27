
{log, logObj} = require('./log') ' MAIN'
console.log ''

{noNet} = require './global'

modules = [
  './xbee',
  './wifi',
  './wx-station'
  './temp'
  './websock-server'
  './tstat'
  './control'
  './timing'
  './insteon'
  './lighting'
  './logging'
  './scroll'
  # './echo'
  './debug'
]

for module in modules
  if noNet and module in ['./xbee', './timing']
    continue
  log 'starting', module
  require(module).init?()
