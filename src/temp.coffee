###
  src/temp.coffee
  xbee packet stream -> filtered/rounded/unique temp streams for each sensor
###

log = (args...) -> console.log 'TEMP:', args...

mockAirIn  = no
mockFreeze = no

Rx      = require 'rx'
xbee    = require './xbee'
emitSrc = new (require('events').EventEmitter)

tempResolution = 1
tempHysterisis = 0.05
numHistory     = 10
dampening      = 30000

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
lastTemps = {}

observers = {}

module.exports =
  init: (@obs$) -> 
    
    addObs = (name, debounceMS) =>
      emitSrc.on name, (rawTemp) ->
        now = Date.now()
        history = histories[name] ?= []
        history.unshift [rawTemp, now]
        weightSum = weightedTempSum = 0
        for oldHist in history
          [histTemp, histTime] = oldHist
          histWeight = Math.max 0, 
            Math.sin(Math.PI/2 + ((now - histTime)/dampening))
          weightSum       += histWeight
          weightedTempSum += histWeight * histTemp 
        temp               = weightedTempSum / weightSum
        rndedTemp          = +temp.toFixed tempResolution
        lastTemp           = (lastTemps[name] ?= temp)
        lastRndedTemp      = +lastTemp.toFixed tempResolution
        lastTemps[name]    = temp
        if Math.abs(temp - lastTemp) < tempHysterisis and
            rndedTemp isnt lastRndedTemp
          rndedTemp = lastRndedTemp
        if history.length > numHistory then history.pop()
        for obs in observers[name] ? []
          obs.onNext (if mockAirIn or mockFreeze then rawTemp else rndedTemp)
  
      @obs$['temp_' + name + '$'] = 
        Rx.Observable.create (observer) ->
          observers[name] ?= []
          observers[name].push observer
        .distinctUntilChanged()
        .debounce debounceMS

    for name, addr of xbeeRadios then do (name, addr) ->        
      xbee.getPacketsByAddr$(name, addr).forEach (item) ->
        {packet} = item
        volts  = ((packet[19] * 256 + packet[20]) / 1024) * 1.2
        if name is 'closet'
          temp = ((voltsAtZeroC - volts ) / voltsPerC) * 9/5 + 32
          if not mockAirIn then emitSrc.emit 'airIntake', temp
          volts = ((packet[21] * 256 + packet[22]) / 1024) * 1.2
          temp =  (voltsAtZeroC - volts) / voltsPerC
          if not mockFreeze then emitSrc.emit 'acReturn', temp
        else
          emitSrc.emit name, volts * 100 
          
    for name of xbeeRadios when name isnt 'closet' then addObs name, 1e3
    for name in ['airIntake', 'acReturn'] 
      addObs name, (if mockAirIn or mockFreeze then 1e3 else 30e3)
      
    if mockAirIn
      t = 0
      setInterval ->
        emitSrc.emit 'airIntake', 70 + Math.sin(t++ * 0.2) * 10
      , 1000
    
    if mockFreeze
      t = 0
      setInterval ->
        emitSrc.emit 'acReturn', 0 + Math.sin(t++ * 0.2) * 10
      , 1000
    