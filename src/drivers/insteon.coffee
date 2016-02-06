###
  src/drivers/insteon.coffee
  timing dampers/hvac in -> insteon relays in closet
###

disableHvacCtrl = no

{log, logObj} = require('./utils') 'INSTE'

$ = require('imprea')()
$.output 'inst_switch'

insteonIds =
  serverGateway:        '2413fd'
  furnaceHvac:          '387efd'
  furnaceDampers:       '387b9e'
  lightsRemote1:        '270b8a'
  lightsRemote2:        '270b00'
  controlRemote:        '27178d'
  lftFrontBulb:         '2c5134' # was '297ebf'
  midFrontBulb:         '29802b'
  rgtFrontBulb:         '2b4f44' # '2b4c44'??   # was '298243'
  lftRearBulb:          '2982c1'
  midRearBulb:          '298cda'
  rgtRearBulb:          '29814c'
  masterDimmer:         '24e363'
  masterLightsRemote:   '1c5a16'
  tVRoomHallDoorRemote: '290758'
  tVRoomFrontDoorRemote:'2902a6'
  
  
############ DRIVER ###########

Insteon = require("home-controller").Insteon
plm = new Insteon()

serialDevice = '/dev/insteon'
device = 'io'
cmd    = 'set'
async  = no

insteonIO = (data) ->
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
          # res.writeHead 404, 'Content-Type': 'text/text'
          # res.end msg
        # else
          # res.writeHead 200, 'Content-Type': 'text/json'
          # res.end JSON.stringify asyncResp ? error: 'No async response.'
    # if not async
      # res.writeHead 200, 'Content-Type': 'text/json'
      # res.end JSON.stringify syncResp ? error: 'No sync response.'
  catch e  
    log 'exception', e
    msg = 'invalid request or no plm response: ' + data[0]
    log msg
    res.writeHead 404, 'Content-Type': 'text/text'
    res.end msg

plm.serial serialDevice, ->
  log 'plm connected to ' + serialDevice

############### SEND #################

send = (isDamper, obj, cb) ->
  logObj 'send ' + (if isDamper then 'damp' else 'hvac'), obj
  id = (if isDamper then insteonIds.furnaceDampers  \
                    else insteonIds.furnaceHvac)
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
  insteonIO [id, dataHex]
  
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


######### RECEIVE ########
###
#  lightsRemote1:        '270b8a'

maxRetries    =     3
nakRetry      =  1000
IMtimeout 	  =  4000
deviceTimeout =  4000
statTimeout 	= 13000

INSTEON_PLM_START 		= 0x02
INSTEON_PLM_NAK 			= 0x15
INSTEON_PLM_TIME_LIMIT 	= 240

INSTEON_MESSAGES =
  # commands sent to serial port (IM)
  '60': #
    type: "Get IM Info"
    len: 9
  '62': # no defined length [must check message flag]
    type: "Send INSTEON Standard or Extended Message"
  '6b':
    type: "Set modem config -- monitor mode"
    len: 4
  '6d':
    type: "LED On"
    len: 3
  '6e':
    type: "LED Off"
    len: 3

  # commands received from serial port (IM)
  '50':
    type: "INSTEON Standard Message Received"
    len: 11
  '51':
    type: "INSTEON Extended Message Received"
    len: 25

lastDbg = 0

dec2binstr = dec2binstr = (str, padding) ->
	bin = Number(str).toString(2)
	bin = "0" + bin  while bin.length < padding
	bin

dec2hex = dec2hex = (str, padding = 2) ->
	hex = Number(str).toString 16
	while hex.length < padding then hex = '0' + hex
	hex

arr2hexStr = arr2hexStr = (ba, spc) ->
	len = '' + ba.length
	if len.length < 2 then len = ' ' + len
	str = (if spc then '(' + len + ') ' else '')
	for byt in ba
		str += dec2hex(byt) + (if spc then ' ' else '')
	str

hexStr2arr = hexStr2arr = (hex) ->
	arr = []
	for i in [0...hex.length] by 2
		arr.push parseInt hex[i..i+1], 16
	arr

byteArrayToHexStringArray = byteArrayToHexStringArray = (ba) ->
  data = []
  i = 0
  while i < ba.length
    data.push dec2hex(ba[i])
    i++
  data

getInsteonCommandType = getInsteonCommandType = getInsteonCommandType = (aByte) ->

  # given insteon command code (second byte) return associated type of message in plaintext
  msg = dec2hex(aByte)
  return INSTEON_MESSAGES[msg].type  unless typeof (INSTEON_MESSAGES[msg]) is "undefined"
  "" # not implemented

getMessageFlags = getMessageFlags = getMessageFlags = (aByte) ->

  # returns parsed message flag in json
  binstr = dec2binstr(aByte, 8)
  type = binstr.substring(0, 3)
  switch type
    when "000"
      type = "Direct Message"
    when "001"
      type = "ACK of Direct Message"
    when "010"
      type = "ALL-Link Cleanup Message"
    when "011"
      type = "ACK of ALL-Link Cleanup Message"
    when "100"
      type = "Broadcast Message"
    when "101"
      type = "NAK of Direct Message"
    when "110"
      type = "ALL-Link Broadcast Message"
    when "111"
      type = "NAK of ALL-Link Cleanup Message"
    else
      throw "getMessageFlags:: undefined message type " + type + ""
  extended = parseInt(binstr.substring(3, 4), 2)
  hops_left = parseInt(binstr.substring(4, 6), 2)
  max_hops = parseInt(binstr.substring(6), 2)
  type: type
  extended: extended
  hops_left: hops_left
  max_hops: max_hops

#
# break an insteon message into various parts
#
parseMsg = parseMsg = (byteArray) ->

  data =
    dec:  byteArray
    hex:  byteArrayToHexStringArray byteArray
    cmd:  byteArray[1]
    type: getInsteonCommandType byteArray[1]

  switch data.type

    when "Button Event Report"
      data.button_event = data.hex[2]

    when "Get IM Info"
      data.device_id = data.hex.slice(2, 5)
      data.device_cat = data.hex[5]
      data.device_subcat = data.hex[6]
      data.device_firmware = data.hex[7]
      data.ack_nak = data.hex[8]

    when "INSTEON Standard Message Received"
      data.from = data.hex.slice(2, 5)
      data.to = data.hex.slice(5, 8)
      data.message_flags = data.hex[8]
      data.command1 = data.hex[9]
      data.command2 = data.hex[10]
      data.message_flags_details = getMessageFlags(data.dec[8])

    when "INSTEON Extended Message Received"
      data.from = data.hex.slice(2, 5)
      data.to = data.hex.slice(5, 8)
      data.message_flags = data.hex[8]
      data.command1 = data.hex[9]
      data.command2 = data.hex[10]
      data.user_data = data.hex.slice(11)

    when "Send INSTEON Standard or Extended Message"
      data.to = data.hex.slice(2, 5)
      data.message_flags = data.hex[5]
      data.command1 = data.hex[6]
      data.command2 = data.hex[7]
      if data.hex.length is 9 # standard
        data.ack_nak = data.hex[8]
      else if data.hex.length is 23 # extended
        data.user_data = data.hex.slice(8, 22)
        data.ack_nak = data.hex[22]
      else
        throw ("insteonjs: standard or extended messages is invalid")

    when "Get IM utilsuration"
      data.utils_flags = data.hex[2]
      data.ack_nak = data.hex[5]

    when "Set IM utilsuration"
      data.utils_flags = data.hex[2]
      data.ack_nak = data.hex[3]

    when "Get First ALL-Link Record"
      data.ack_nak = data.hex[2]

    when "Get Next ALL-Link Record"
      data.ack_nak = data.hex[2]

    when "Start ALL-Linking"
      data.link_code = data.hex[2]
      data.all_link_group = data.hex[3]
      data.ack_nak = data.hex[4]

    when "Cancel ALL-Linking"
      data.ack_nak = data.hex[2]

    when "ALL-Link Record Response"
      data.record_flags = data.hex[2]
      data.link_group = data.hex[3]
      data.deviceid = data.hex.slice(4, 7)
      data.data1 = data.hex[7]
      data.data2 = data.hex[8]
      data.data3 = data.hex[9]

    when "Send ALL-Link Command"
      data.all_link_group = data.hex[2]
      data.all_link_command = data.hex[3]
      data.broadcast_cmd2 = data.hex[4]

    when "ALL-Linking Completed"
      data.link_code = data.hex[2]
      data.link_group = data.hex[3]
      data.device_id = data.hex.slice(4, 7)
      data.device_cat = data.hex[7]
      data.device_subcat = data.hex[8]
      data.device_firmware = data.hex[9]

    when "Reset the IM"
      data.ack_nak = data.hex[2]

    else
      data.error = "Unrecognized command or command not implemented"

  if byteArray[0] is INSTEON_PLM_NAK
    data.error = "PLM NAK received (buffer overrun)"

  data

parser = ->
	data = []
	messages = []
	msglen = -1
	start = 0

	(emitter, buffer) ->
#		console.log 'buffer in', buffer, buffer.length

		for b in buffer
			if start and Date.now() - start > INSTEON_PLM_TIME_LIMIT
				start = Date.now()
				if data.length
					log 'parser: Incomplete message ( '+
						arr2hexStr(data) +
						') discarded, exceeded time limit'
					data = []
				msglen = -1

			if msglen is -1
				if b is INSTEON_PLM_NAK
					msglen = 1

				else if b is INSTEON_PLM_START
					msglen = 0
					start = Date.now()
					if data.length
						log "parser: Incomplete message (" +
							arr2hexStr(data) +
							") discarded, unknown command length"
						msglen = -1
						data = []

			data.push b

			if data.length is 2 and msglen is 0
				cmdByt = dec2hex data[1]
				if not (msglen = INSTEON_MESSAGES[cmdByt]?.len) then msglen = -1

			else if data.length is 6 and dec2hex(data[1]) is "62"
				msglen = (if (data[5] & 0x10) is 0x10 then 23 else 9)

			else if data.length > 0 and msglen is data.length
			  messages.push data
			  data = []
			  msglen = -1
			  start = 0

#			b = dec2hex b
#			console.log {b, msglen, data, messages}

#		console.log 'end buffer', {b, msglen, data, messages}

		for msg in messages
			if showRecvData then log 'recv    srl', arr2hexStr msg, yes
			emitter.emit 'message', msg
		messages = []

serial.port = new SerialPort portName,
    baudrate: 19200,
    databits: 8,
    stopbits: 1,
    parity: 0,
    flowcontrol: 0,
    parser: parser()

serial.port.on 'error', (err) ->
	console.log 'ERROR from port', err

###
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

    setTimeout ->
      $.inst_switch 'test'
    , 3000