###
  src/lighting.coffee
###

{log, logObj} = require('./utils') 'LIGHT'

$ = require('imprea')()
$.output 'light_cmd'

bulbs = [
  'frontLeft'
  'frontMiddle'
  'frontRight' 
  'backLeft'
  'backMiddle'
  'backRight'
]
scenes = [
  [1,0,1, 0,0,1]
  [1,0,1, 1,0,1]
  [0,0,0, 0,0,1]
  [0,0,0, 1,0,0]
  [1,1,1, 0,0,0]
  [0,0,0, 1,1,1]
]
scene   = [1,1,1, 1,1,1]
level   = 32
dimmed  = no
lastBtn = sceneIdx = 0

module.exports =
  init: -> 
    $.react 'inst_remote', ->
      btn = $.inst_remote.btn
      scene = switch btn
        when 1 
          dimmed = no
          [1,1,1, 1,1,1]
        when 2
          dimmed = no
          [0,0,0, 0,0,0]
        when 3
          if lastBtn is 3 then sceneIdx++
          scenes[sceneIdx % scenes.length]
        when 4
          dimmed = not dimmed
          scene
        when 5
          level = Math.min 255, level*2
          dimmed = yes
          scene
        when 6
          level = Math.max 0, level/2; scene
          dimmed = yes
          scene
        else scene
      lastBtn = btn
      for val, i in scene
        $.light_cmd 
          bulb:  bulbs[i]
          cmd:  'moveTo'
          val:   
            level: val * (if dimmed then level else 255)
            time: (if btn is 3 then 0 else 1)
