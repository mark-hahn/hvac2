
log = (args...) -> console.log ' MAIN:', args...
console.log ''

mods = [
  './xbee', 
  './wx-station'
  './temp'
  './websock-server'
  './tstat'
  './control'
  './timing'
  './insteon'
  './debug'
]
obs$ = {}
for mod in mods 
  # log 'starting', mod
  require(mod).init obs$
  