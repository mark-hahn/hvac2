
log = (args...) -> console.log 'TEMP:', args...

Rx      = require 'rx'
xbee    = require './xbee'
emitSrc = new (require('events').EventEmitter)

tempResolution = 10

xbeeRadios = 
  tvRoom : 0x0013a20040c33695
  kitchen: 0x0013a20040b3a592
  master:  0x0013a20040b3a903
  guest:   0x0013a20040b3a954
  closet:  0x0013A20040BD2529
  
voltsAtZeroC = 1.05
voltsAt25C   = 0.83
voltsPerC    = (voltsAtZeroC - voltsAt25C) / 25
  
histories = {}
for name of xbeeRadios when name isnt 'closet'
  histories[name] = []
histories.acReturn = []
histories.airIn    = []
  
filterTemp = (name, temp) ->
  history = histories[name]
  history.push temp
  if history.length > 10 then history.shift()
  sum = 0
  for temp in history
    sum += temp
  Math.round((sum / history.length)*tempResolution)/tempResolution
  
module.exports =
  init: (@obs$) -> 
    
    @obs$.temp_airIn$ = 
      Rx.Observable.fromEvent emitSrc, 'airIn'
        .map (temp) -> filterTemp 'airIn', temp
        .distinctUntilChanged()
    @obs$.temp_acReturn$ = 
      Rx.Observable.fromEvent emitSrc, 'acReturn'
        .map (temp) -> filterTemp 'acReturn', temp
        .distinctUntilChanged()
    
    for name, addr of xbeeRadios then do (name, addr) =>
      
      if name isnt 'closet'
        @obs$['temp_' + name + '$'] = 
          Rx.Observable.fromEvent emitSrc, name
            .map (temp) -> filterTemp name, temp
            .distinctUntilChanged()
        
      xbee.getPacketsByAddr$(name, addr).forEach (item) ->
        {packet} = item
        volts  = ((packet[19] * 256 + packet[20]) / 1024) * 1.2
        if name is 'closet'
          temp = ((voltsAtZeroC - volts ) / voltsPerC) * 9/5 + 32
          emitSrc.emit 'airIn', temp
          volts = ((packet[21] * 256 + packet[22]) / 1024) * 1.2
          temp =  (voltsAtZeroC - volts) / voltsPerC
          emitSrc.emit 'acReturn', temp
        else
          emitSrc.emit name, volts * 100 
        
