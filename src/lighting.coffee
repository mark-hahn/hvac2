###
  src/lighting.coffee
###

{log, logObj} = require('./utils') 'LIGHT'

$ = require('imprea')()

$.output 'light_cmd'

module.exports =
  init: -> 
    $.react 'inst_remote', ->
      onOffStr = (if ($.inst_remote.btn & 1) is 0 then 'off' else 'on')
      $.light_cmd bulb: 'frontLeft',   action: onOffStr
      $.light_cmd bulb: 'frontMiddle', action: onOffStr
      $.light_cmd bulb: 'frontRight',  action: onOffStr
      $.light_cmd bulb: 'backLeft',    action: onOffStr
      $.light_cmd bulb: 'backMiddle',  action: onOffStr
      $.light_cmd bulb: 'backRight',   action: onOffStr
    
