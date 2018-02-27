{log} = require('./log') ' WIFI'

{noNet} = require './global'
if noNet then return

$ = require('imprea')()
emitSrc = new (require('events').EventEmitter)

TPLSmartDevice = require 'tplink-lightbulb'

device =
  frontLeft:   new TPLSmartDevice '192.168.1.163'
  frontRight:  new TPLSmartDevice '192.168.1.164'

exports.init = ->
  # log 'wifi init'
  $.react 'light_cmd', ->
    {bulb, cmd, val} = $.light_cmd
    # log 'wifi light_cmd', {bulb, cmd, val}

    if bulb is 'tvall'
      if val.level == 0
        device.frontLeft.power(false).catch (e) => log e
        device.frontRight.power(false).catch (e) => log e
      else
        # log val.level, brightness: Math.round((val.level/255)*100)
        device.frontLeft.power on, 0, brightness: Math.round((val.level/255)*100)
            .then (response) => #log response
            .catch (e) => log e
        device.frontRight.power on, 0, brightness: Math.round((val.level/255)*100)
            .then (response) => #log response
            .catch (e) => log e
      return

    if not light = device[bulb] then return
    switch cmd
      when 'moveTo'
        if val.level == 0
          light.power(false).catch (e) => log e
        else
          # log val.level, brightness: Math.round((val.level/255)*100)
          light.power on, 0, brightness: Math.round((val.level/255)*100)
              .then (response) => # log response
              .catch (e) => log e
        return
