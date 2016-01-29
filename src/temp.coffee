###
  src/temp.coffee
  xbee packet stream -> filtered/rounded/unique temp streams for each sensor
###

{log, logObj} = require('./utils') ' TEMP'

$       = require('imprea')()
xbee    = require './xbee'
emitSrc = new (require('events').EventEmitter)

tempResolution = 1
tempHysterisis = 0.05
numHistory     = 10
dampening      = 30000

offset = {tvRoom: -3, kitchen: -2.0, master: +2.0, guest: -1.5, airIntake: -3.0, acReturn:0}

xbeeRadios = 
# server:  0x0013a20040c33695  
  tvRoom : '0013a20040baffad'
  kitchen: '0013a20040b3a592'
  master:  '0013a20040b3a903'
  guest:   '0013a20040b3a954'
  closet:  '0013a20040bd2529'
  
voltsAtZeroC = 1.05
voltsAt25C   = 0.83
voltsPerC    = (voltsAtZeroC - voltsAt25C) / 25
  
histories = {}
lastTemps = {}

module.exports =
  init: -> 
    
    addObs = (name) ->
      obsName = 'temp_' + name 
      $.output obsName
      
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
        $[obsName] rndedTemp + offset[name] ? 0

    for name, addr of xbeeRadios then do (name, addr) ->        
      xbee.getPacketsByAddr name, addr
      obsName = 'xbeePacket_' + name
      $.react obsName, ->
        {analogData} = $[obsName]
        volts  = (analogData[0] / 1024) * 1.2
        if name is 'closet'
          temp = ((voltsAtZeroC - volts ) / voltsPerC) * 9/5 + 32
          emitSrc.emit 'airIntake', temp
          volts = (analogData[1] / 1024) * 1.2
          temp =  (voltsAtZeroC - volts) / voltsPerC
          emitSrc.emit 'acReturn', temp
        else
          emitSrc.emit name, volts * 100 
          
    for name of xbeeRadios when name isnt 'closet' then addObs name
    for name in ['airIntake', 'acReturn']          then addObs name
          
          