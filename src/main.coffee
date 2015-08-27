
log = (args...) -> console.log ' MAIN:', args...

log 'Starting ...'

# all observables in the app
allObservables = {}

mods = [
  './xbee', 
  './debug'
]

for mod in mods then require(mod).setAllObservables allObservables
