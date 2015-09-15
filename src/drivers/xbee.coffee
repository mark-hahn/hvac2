
{log, logObj} = require('./utils') ' XBEE'

$ = require('imprea')()
SerialPort = require('serialport').SerialPort
emitSrc = new (require('events').EventEmitter)

$.output 'allXbeePackets'

module.exports =
  init: -> 
    emitSrc.on 'newPacket', (pktAddr, packet) ->
      # log 'newPacket', pktAddr
      $.allXbeePackets {pktAddr, packet}
  
  getPacketsByAddr: (name, addr) ->
    name = 'xbeePacket_' + name
    $.output name
    emitSrc.on 'newPacket', (pktAddr, packet) ->
      if pktAddr is addr
        $[name] {addr, packet}

xbeeSerialPort = new SerialPort '/dev/xbee',
  baudrate: 9600,
  databits: 8,
  stopbits: 1,
  parity: 0,
  flowcontrol: 0,

frameBuf = []

getFrameLen = (index) ->
  if frameBuf.length < index+4 then return 0
  if frameBuf[index+0] is 0x7e and
      (frameLen = frameBuf[index+1]*256 + frameBuf[index+2] + 4) and
      frameLen in [22,24] and frameBuf[index+3] is 0x92
    frameLen
  else 0

assembleFrame = (data) ->
  # log 'recv data', data
  for i in [0...data.length] then frameBuf.push data[i]

  loop
    if (frameLen = getFrameLen 0) and frameBuf.length >= frameLen
      frame = frameBuf.splice 0, frameLen
      cksum = 0
      for byte in frame[3..frameLen-2] then cksum += byte
      cksum &= 0xff
      if (0xff - cksum) isnt frame[frameLen-1]
        log 'xBee checksum error', frame
        frameBuf = []
      else
        srcAddr = 0
        for idx in [4...12] by 1
          srcAddr *= 256
          srcAddr += frame[idx]
        # log 'emitSrc.emit newPacket', srcAddr
        emitSrc.emit 'newPacket', srcAddr, frame 
    else
      break

  for index in [0..frameBuf.length-4]
    if (frameLen = getFrameLen index)
      frameBuf.splice 0, index
      break

xbeeSerialPort.on 'open', ->
  log 'Port open'
  xbeeSerialPort.on 'data', assembleFrame

xbeeSerialPort.on 'error', (err) ->
  log 'ERROR: from port', err

###
contents of /etc/udev/rules.d/99-home-serial-usb.rules
SUBSYSTEMS=="usb-serial", DRIVERS=="cp210x", ATTRS{port_number}=="0", SYMLINK+="davis"
SUBSYSTEMS=="usb", ATTRS{serial}=="A6028N89", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6001", SYMLINK+="insteon"
SUBSYSTEMS=="usb", ATTRS{serial}=="A5025MT6", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6001", SYMLINK+="xbee"
###

# sensors
# function set ZigBee Router AT
# Firmware 22A7
# ID 6392
# SC 40
# D1 ADC[2]
# PR 1FF7
# IR 1000

# acline
# function set ZigBee Router AT
# Firmware 22A7
# ID 6392
# SC 40
# D1 ADC[2]
# D2 ADC[2]
# PR 1FF3
# IR 1000

#server
# product family XB24-ZB
# function set ZigBee Coordinator API
# Firmware 21A7
# MAC: 0013A20040BAFFAD
# ID 6392
# SC 40

