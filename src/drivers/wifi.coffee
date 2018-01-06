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
  log 'wifi init'
  $.react 'light_cmd', ->
    {bulb, cmd, val} = $.light_cmd
    if not light = device[bulb] then return
    log 'wifi light_cmd', {bulb, cmd, val}
    switch cmd
      when 'moveTo'
        if val.level == 0
          light.power(false).catch (e) => log e
        else
          log ((val.level/255)*100).toFixed(0), brightness: ((val.level/255)*100).toFixed(0)
          light.power brightness: ((val.level/255)*100).toFixed(0)
              .then (response) => log response
              .catch (e) => log e
        return
