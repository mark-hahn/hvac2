###
  src/drivers/insteon.coffee
  timing dampers/hvac in -> insteon relays in closet
###

{log, logObj} = require('./log') 'INSTE'

disableHvacCtrl = no

{noNet} = require './global'
if noNet then return

log "1"
Insteon = require("hahn-controller").Insteon
log "2"

plm = new Insteon()

$ = require('imprea')()
$.output 'inst_remote'

############ CONSTANTS ###########
serialDevice = '/dev/insteon'

insteonIdsByName =
  serverGateway:        '448728' # '2413fd'
  furnaceHvac:          '387efd'
  furnaceDampers:       '387b9e'
  lightsRemote1:        '270b8a'
  lightsRemote2:        '270b00'
  lightsRemote3:        '27178d'
  lightsRemoteMaster:   '1c5a16'
  dimmerTvFrontDoor:    '2902a6'
  dimmerTvHallDoor:     '290758'
  dimmerMaster:         '24e363'
  deckBbq:              '2b4f44'
  deckTable:            '29814c'
  patio:                '3e11a8'

insteonNamesById = {}
for name, id of insteonIdsByName
  insteonNamesById[id] = name


############### SEND #################

send = (isDamper, obj, cb) ->
  if disableHvacCtrl then cb?(); return

  id = (if isDamper then insteonIdsByName.furnaceDampers  \
                    else insteonIdsByName.furnaceHvac)
  data = 0
  for name, val of obj
    bit = switch name
      when 'tvRoom',  'heat'   then 1
      when 'kitchen', 'cool'   then 2
      when 'master',  'fan'    then 4
      when 'guest',   'extAir' then 8
    if isDamper and not val or not isDamper and val
      data += bit
  # data = '0' + data.toString(16).toUpperCase()  ???? WTF how did this ever work?
  try
    # log 'sending', id, data`
    plm.io(id).set data
  catch e
    log 'ioSet exception: bad request or no response', {id, data}, e
    cb? e
  cb?()

trying = true: {}, false: {}

sendWretry = (isDamper, obj) ->
  logObj 'send ' + (if isDamper then 'damp' else 'hvac'), obj
  trying[isDamper].obj   = obj
  trying[isDamper].count = 4
  do tryOnce = (isDamper) ->
    if trying[isDamper].TO
      clearTimeout trying[isDamper].TO
      delete trying[isDamper].TO
    send isDamper, trying[isDamper].obj, ->
      if trying[isDamper].count-- > 0
        trying[isDamper].TO = setTimeout (-> tryOnce isDamper), 5e3


######### RECEIVE REMOTES #########

cmdTimeout  = 500
lastCmdHash = null
lastTime = emitSeq = 0

recvCommand = (cmd) ->
  # if cmd.standard?.command1 isnt '62'
    # log 'recvCommand', cmd
  now = Date.now()
  if cmd.standard?.type isnt '50' then return
  {id, gatewayId:gw, command1:cmd1, command2:cmd2} = cmd.standard
  if gw > '000008' then return
  cmdHash = [id, gw, cmd1, cmd2].join '~'
  if cmdHash is lastCmdHash and now < lastTime + cmdTimeout
    lastCmdHash = null
    lastTime    = 0
    return
  lastCmdHash = cmdHash
  lastTime = now
  action = switch cmd1
    when '11' then 'click'
    when '12' then 'dblClick'
    when '13' then 'click'
    when '14' then 'dblClick'
    when '17' then 'down'
    when '18' then 'up'
    else cmd
  name = insteonNamesById[id]
  if not name then return

  btn = switch name[0..5]
    when 'lights' then +gw
    when 'dimmer'
      switch cmd1
        when '11', '12' then 1
        when '13', '14' then 2
        when '17'       then 2 - +cmd2
        when '18'       then 0
  # log 'button', btn, action, 'on', name
  $.inst_remote {remote: name, btn, action, seq: ++emitSeq}

plm.serial serialDevice, ->
  log 'plm connected to ' + serialDevice
  plm.on 'recvCommand', recvCommand

plm.on 'error', (err) -> log 'insteon port err', err

############# MODULE ##############

module.exports =
  init: ->
    $.react 'timing_dampers', ->
      sendWretry yes, @timing_dampers
    $.react 'timing_hvac', ->
      sendWretry no, @timing_hvac
    sendWretry no,  {extAir: off, fan: off,    heat: off, cool: off}
    sendWretry yes, {tvRoom: on,  kitchen: on, master:on, guest: on}

    $.react 'light_cmd', ->
      {bulb, cmd, val} = $.light_cmd
      log 'lights', {bulb, cmd, val}
      if bulb not in ['deckBbq', 'deckTable', 'patio'] or
          cmd not in ['moveTo', 'dim']
        return
      {level, time} = val
      light = plm.light insteonIdsByName[bulb]
      if cmd is 'dim'
        # log 'dim light:', bulb, light.id
        light.brighten()
        return
      level = Math.round level * 100 / 255
      # log 'send light:', bulb, level, light.id
      switch level
        when 0   then light.turnOff()
        when 100 then light.turnOn()
        else          light.turnOn level
