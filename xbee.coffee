
# 7CE52400001465BD

{log, logObj} = require('./js/utils') ' XBEE'

SerialPort = require('serialport').SerialPort
  
xbeeSerialPort = new SerialPort '/dev/xbee',
  baudrate: 9600,
  databits: 8,
  stopbits: 1,
  parity: 0,
  flowcontrol: 0,

frameBuf = []

dec2hex = (arr, start=0, end=arr.length) ->
  if end < 0 then end += arr.length
  hexArr = []
  for i in [start...end]
    hex = arr[i].toString 16
    if hex.length < 2 then hex = '0' + hex
    hexArr.push hex
  hexArr.join ' '
  
getFrameLen = (index) ->
  if frameBuf.length < index+4 then return 0
  if frameBuf[index+0] is 0x7e
    frameBuf[index+1]*256 + frameBuf[index+2] + 4
  else 
    0

addr64 = (arr, idx) ->
  srcAddr = 0
  for i in [idx...idx+8] by 1
    srcAddr *= 256
    srcAddr += arr[i]
  srcAddr
  
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
        log 'xBee checksum error', dec2hex frame
        frameBuf = []
      else
        switch frame[3] # type
          
          when 0x92  #  IO Data Sample Rx
            if frameLen not in [22,24]
              log 'bad framelen', dec2hex frame
            else
              srcAddr = addr64 frame, 4
              log 'IO  Rx', srcAddr.toString(16), '\n', dec2hex frame
              
          when 0x91 # explicit Rx
            log 'exp rx', dec2hex frame
            
          when 0x88  # AT Command ResponseFrame
            frameId = frame[4]
            ATcmd = String.fromCharCode(frame[5]) + String.fromCharCode(frame[6])
            status = ['OK', 'Error', 'Invalid Command',
                            'Invalid Parameter', 'Tx Failure'][frame[7]]
            whatIsThis = dec2hex [frame[8],frame[9]]
            srcAddr = addr64 frame, 10
            srcAddrStr = srcAddr.toString 16
            data = frame.slice 18, -1
            log 'AT  rx', 
              {frameId, ATcmd, status, whatIsThis, srcAddr: srcAddrStr}, '\n', 
               dec2hex data
          else
            log '??? rx', dec2hex frame
    else
      break

  for index in [0..frameBuf.length-4]
    if (frameLen = getFrameLen index)
      frameBuf.splice 0, index
      break

write = (dataArr, cb) ->
  log 'write', dec2hex dataArr
  dataLen = dataArr.length
  buf = new Buffer 4 + dataLen
  buf.writeUInt8 0x7E, 0
  buf.writeUInt16BE dataLen, 1
  cksum = 0
  for byte, idx in dataArr
    buf.writeUInt8 byte, 3 + idx
    cksum += byte
  buf.writeUInt8 0xFF - (cksum & 0xFF), 3 + dataLen
  
  if not xbeeSerialPort.isOpen()
    log 'attempted write while closed', buf.toString()
    cb 'attempted write while closed'
    return
  xbeeSerialPort.write buf, (err, writeLen) ->
    if err
      log 'write err', {buf, err}
      cb? err
      return
    if writeLen isnt buf.length
      log 'write length wrong', {buf, writeLen}
      cb? 'write length wrong'
      return
    xbeeSerialPort.flush (err) ->
      if err
        log 'flush err', {buf, err}
        cb? err
        return
      xbeeSerialPort.drain (err) ->
        if err
          log 'drain err', {buf, err}
          cb? err
          return
        cb?()

ATcmd = (frameId, cmd, data, cb) ->
  if typeof data is 'function' then cb = data; data = []
  writeData = [0x08, frameId, cmd.charCodeAt(0), cmd.charCodeAt(1)].concat data
  write writeData, cb

discovery = (cb) ->
  ATcmd 1, 'ND', ->
    log 'discovery end'

xbeeSerialPort.on 'open', ->
  log 'Port open'
  xbeeSerialPort.on 'data', assembleFrame
  
  discovery()

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

