
log = (args...) -> console.log ' MAIN:', args...
console.log ''

mods = [
  './xbee', 
  './wx-station'
  './temp'
  './websocket'
  './tstat'
  './control'
  './debug'
]
obs$ = {}
for mod in mods 
  log 'starting', mod
  require(mod).init obs$
