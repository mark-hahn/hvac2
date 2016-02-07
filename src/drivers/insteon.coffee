###
  src/drivers/insteon.coffee
  timing dampers/hvac in -> insteon relays in closet
###
  
{log, logObj} = require('./utils') 'INSTE'
Insteon = require("home-controller").Insteon
plm = new Insteon()
$ = require('imprea')()
$.output 'inst_remote'

disableHvacCtrl = no

############ CONSTANTS ###########
serialDevice = '/dev/insteon'
  
insteonIdsByName =
  serverGateway:        '2413fd'
  furnaceHvac:          '387efd'
  furnaceDampers:       '387b9e'
  lftFrontBulb:         '2c5134'
  midFrontBulb:         '29802b'
  rgtFrontBulb:         '2b4f44'
  lftRearBulb:          '2982c1'
  midRearBulb:          '298cda'
  rgtRearBulb:          '29814c'
  lightsRemote1:        '270b8a'
  lightsRemote2:        '270b00'
  lightsRemote3:        '27178d'
  lightsRemoteMaster:   '1c5a16'
  dimmerTvFrontDoor:    '2902a6'
  dimmerTvHallDoor:     '290758'
  dimmerMaster:         '24e363'

insteonNamesById = {}
for name, id of insteonIdsByName
  insteonNamesById[id] = name


############ DRIVER ###########

device = 'io'
cmd    = 'set'
async  = no

insteonSend = (data) ->
  try
    deviceInstance = (if device is 'plm' then plm \
                      else id = data.shift(); plm[device](id, plm))
    syncResp = deviceInstance[cmd].call deviceInstance, data...
    , (err, asyncResp) ->
      log 'async cb', {async, err, asyncResp}
      if async
        if err
          msg = 'async response error: ' + req.url + ', ' + JSON.stringify err
          log msg
  catch e  
    log 'exception', e
    msg = 'invalid request or no plm response: ' + data[0]
    log msg
    res.writeHead 404, 'Content-Type': 'text/text'
    res.end msg


############### SEND #################

send = (isDamper, obj, cb) ->
  logObj 'send ' + (if isDamper then 'damp' else 'hvac'), obj
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
  dataHex = '0' + data.toString(16).toUpperCase()
  insteonSend [id, dataHex]
  
tryTO = {}

sendWretry = (isDamper, obj) ->
  if tryTO[''+isDamper]
    clearTimeout tryTO[''+isDamper]
    delete tryTO[''+isDamper]
    
  do tryOnce = (isDamper, obj, tries = 0) ->
    delete tryTO[''+isDamper]
    
    send isDamper, obj, (err) ->
      if err
        if ++tries > 12
          log 'giving up, too many retries of insteon command'
          return
        tryTO[''+isDamper] = setTimeout (-> tryOnce isDamper, obj, tries), 5e3


######### RECEIVE REMOTES #########

cmdTimeout  = 500
lastCmdHash = null
lastTime = emitSeq = 0

recvCommand = (cmd) ->
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


############# MODULE ##############

module.exports =
  init: -> 
    $.react 'timing_dampers', ->
      sendWretry yes, @timing_dampers
    $.react 'timing_hvac', ->
      sendWretry no, @timing_hvac
    sendWretry no,  {extAir: off, fan: off,    heat: off, cool: off}
    sendWretry yes, {tvRoom: on,  kitchen: on, master:on, guest: on}
    
    log 'relays cleared'
  