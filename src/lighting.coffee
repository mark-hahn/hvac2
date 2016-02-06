###
  src/lighting.coffee
###

{log, logObj} = require('./utils') 'LIGHT'

$ = require('imprea')()

$.output 'light_onOff'

module.exports =
  init: -> 
    $.react 'inst_switch', ->
      $.light_onOff $.inst_switch
    
    
    
