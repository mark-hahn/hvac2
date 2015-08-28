
log = (args...) -> console.log 'TEMP:', args...

Rx      = require 'rx'
xbee    = require './xbee'
emitSrc = new (require('events').EventEmitter)

tempResolution = 100

xbeeRadios = 
  tvRoom : 0x0013a20040c33695
  kitchen: 0x0013a20040b3a592
  master:  0x0013a20040b3a903
  guest:   0x0013a20040b3a954
  closet:  0x0013A20040BD2529
  
voltsAtZeroC = 1.05
voltsAt25C   = 0.83
voltsPerC    = (voltsAtZeroC - voltsAt25C) / 25
  
# scanFunc = (history, temp) ->
#   history.push temp
#   history.splice -10, 1
#   sum = 0
#   for h in history
#     sum += h
#   
#   history
  
module.exports =
  init: (@obs$) -> 
    
    @obs$.temp_airIn$ = 
      Rx.Observable.fromEvent emitSrc, 'airIn'
        .distinctUntilChanged()
    @obs$.temp_acReturn$ = 
      Rx.Observable.fromEvent emitSrc, 'acReturn'
        .distinctUntilChanged()
    
    for name, addr of xbeeRadios then do (name, addr) =>
      
      if name isnt 'closet'
        @obs$['temp_' + name + '$'] = 
          Rx.Observable.fromEvent emitSrc, name
            .distinctUntilChanged()
        
      xbee.getPacketsByAddr$(name, addr).forEach (item) ->
        {packet} = item
        volts  = ((packet[19] * 256 + packet[20]) / 1024) * 1.2
        if name is 'closet'
          temp = ((voltsAtZeroC - volts ) / voltsPerC) * 9/5 + 32
          emitSrc.emit 'airIn', Math.round(temp*tempResolution)/tempResolution
          volts = ((packet[21] * 256 + packet[22]) / 1024) * 1.2
          temp =  (voltsAtZeroC - volts) / voltsPerC
          emitSrc.emit 'acReturn', Math.round(temp*tempResolution)/tempResolution
        else
          temp = volts * 100  
          emitSrc.emit name, Math.round(temp*tempResolution)/tempResolution
        
