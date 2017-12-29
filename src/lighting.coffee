###
  src/lighting.coffee
###

{log, logObj} = require('./log') 'LIGHT'

$ = require('imprea')()
$.output 'light_cmd'

bulbs = [
  'frontLeft'
  'frontMiddle'
  'frontRight'
  'backLeft'
  'backMiddle'
  'backRight'
  'deckBbq'
  'deckTable'
  'patio'
]
scenes = [
  [1,0,1, 0,0,1]
  [1,0,1, 1,0,1]
  [0,0,0, 0,0,1]
  [0,0,0, 1,0,0]
  [0,0,0, 1,0,1]
]
scene     = [1,1,1, 1,1,1]
levelShft = 5
dimmed    = no
lastBtn   = sceneIdx = seq = 0

sceneIdxTO = null
resetSceneIdx = ->
  if sceneIdxTO then clearTimeout sceneIdxTO
  sceneIdxTO = null
  lastBtn = sceneIdx = 0

setLights = (scene, btn, dimmed, level) ->
  for val, i in scene
    $.light_cmd
      __:    seq++
      bulb:  bulbs[i]
      cmd:  'moveTo'
      val:
        level: val * (if dimmed then 1 << levelShft else 255)
        time: (if btn is 3 then 0 else 1)

lastBulb = 'deckBbq'
deckPatioDimIdx = 5

module.exports =
  init: ->
    $.react 'inst_remote', ->
      {remote, btn, action} = $.inst_remote
      if remote is 'lightsRemote3'
        [bulb, level] = switch btn
          when 1 then ['deckBbq',   255]
          when 2 then ['deckBbq',     0]
          when 3 then ['deckTable', 255]
          when 4 then ['deckTable',   0]
          when 5 then ['patio',     255]
          when 6 then ['patio',       0]
          when 7 then deckPatioDimIdx++; ['last']
          when 8 then deckPatioDimIdx--; ['last']
        if bulb is 'last'
          deckPatioDimIdx = Math.max 0, Math.min 8, deckPatioDimIdx
          deckPatioLevel  = (1 << deckPatioDimIdx) - 1
          # log 'inst_remote last', {lastBulb, deckPatioDimIdx, deckPatioLevel}
          $.light_cmd
            __:    seq++
            bulb:  lastBulb
            cmd:  'moveTo'
            val: level: deckPatioLevel
        else
          lastBulb = bulb
          deckPatioDimIdx = 5
          # log 'inst_remote', {bulb, level}
          $.light_cmd
            __:    seq++
            bulb:  bulb
            cmd:  'moveTo'
            val: level: level
        return

      if remote not in [
        'lightsRemote1', 'lightsRemote2'
        'dimmerTvFrontDoor', 'dimmerTvHallDoor'] then return
      if btn > 6 then return
      scene = switch btn
        when 1
          dimmed = no
          [1,1,1, 1,1,1]
        when 2
          dimmed = no
          [0,0,0, 0,0,0]
        when 3
          if lastBtn is 3 then sceneIdx++
          if sceneIdxTO then clearTimeout sceneIdxTO
          sceneIdxTO = setTimeout resetSceneIdx, 3e3
          scenes[sceneIdx % scenes.length]
        when 4
          dimmed = not dimmed
          scene
        when 5
          levelShft = Math.min 7, levelShft + 1
          dimmed = yes
          scene
        when 6
          levelShft = Math.max 1, levelShft - 1
          dimmed = yes
          scene
        else scene
      lastBtn = btn

      setLights scene, btn, dimmed, level
      if btn is 2
        setTimeout ->
          setLights scene, btn, dimmed, level
        , 1000
