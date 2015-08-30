
log = (args...) -> console.log ' MAIN:', args...
console.log ''

mods = [
  './xbee', 
  './wx-station'
  './websocket'
  './temp'
  './tstat'
  './debug'
]
obs$ = {}
for mod in mods 
  log 'starting', mod
  require(mod).init obs$
