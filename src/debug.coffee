
log = (args...) -> console.log 'DEBUG:', args...

Rx = require 'rx'
xbee = require './xbee'

module.exports =
  init: (@obs$) -> 
    @obs$.temp_tvRoom$.forEach (temp) ->
      log 'temp_tvRoom$', temp
      
    @obs$.temp_kitchen$.forEach (temp) ->
      log 'temp_kitchen$', temp
      
    @obs$.temp_master$.forEach (temp) ->
      log 'temp_master$', temp
      
    @obs$.temp_guest$.forEach (temp) ->
      log 'temp_guest$', temp
      
    @obs$.temp_acReturn$.forEach (temp) ->
      log 'temp_acReturn$', temp
      
    @obs$.temp_airIn$.forEach (temp) ->
      log 'temp_airIn$', temp
      
    