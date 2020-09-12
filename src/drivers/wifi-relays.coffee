###
  timing dampers/hvac in -> wifi relays in closet
###

util = require 'util'
{log, logObj} = require('./log') 'RELAY'

disableHvacCtrl = no

{noNet} = require './global'
if noNet then return

$ = require('imprea')()
# $.output 'inst_remote'

req = require("request");
url = 'http://192.168.1.234/?cmd='

############### SEND #################

send = (obj) ->
  log util.inspect obj
  for name, val of obj
    onOff = if(val) then 1 else 0
    cmd = switch name
      # thermostat ctl: val true -> relay closed
      when 'heat'    then 10 + onOff
      when 'cool'    then 20 + onOff
      when 'fan'     then 30 + onOff
      when 'extAir'  then 40 + onOff
      # rooms: val true -> damper open, relay open, damper power off
      when 'tvRoom'  then 50 + 1 - onOff
      when 'kitchen' then 60 + 1 - onOff
      when 'master'  then 70 + 1 - onOff
      when 'guest'   then 80 + 1 - onOff

    req url+cmd, (error, response, body) =>
      if(error) 
        log "http request error: " + cmd + ', ' + error.message
      else if(response.statusCode isnt '200' and response.statusCode isnt 200) 
        log "http request bad status: " + cmd + ', ' + response.statusCode

############# MODULE ##############

module.exports =
  init: ->
    $.react 'timing_dampers', ->
      send @timing_dampers
    $.react 'timing_hvac', ->
      send @timing_hvac
