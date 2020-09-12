
{log, logObj} = require('./log') ' MAIN'
console.log ''

{noNet} = require './global'

modules = [
  './xbee',
  './wifi-lights',
  './wx-station'
  './temp'
  './websock-server'
  './tstat'
  './control'
  './timing'
  './wifi-relays'
  './lighting'
  './logging'
  './scroll'
  './echo'
  './debug'
]

for module in modules
  if noNet and module in ['./xbee', './timing']
    continue
  log 'starting', module
  require(module).init?()
