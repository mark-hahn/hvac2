
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
  
dec2arr = (dec, len) ->
  arr = []
  for i in [1..len]
    arr.unshift (dec & 0xFF)
    dec >>>= 8
  arr

dec2arrLE = (dec, len) ->
  arr = []
  for i in [1..len]
    arr.push (dec & 0xFF)
    dec >>>= 8
  arr

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
            srcAddr = addr64 frame, 4
            srcAddrStr = srcAddr.toString 16
            netAddr = frame[12] * 256 + frame[13]
            netAddrStr = netAddr.toString 16
            rxOptions = switch frame[14]
              when 0x01 then 'ACK'
              when 0x02 then 'BDCST'
            # numSamples = frame[15] --> always 1
            digitalMask    = frame[16] * 256 + frame[17]
            digitalMaskStr = digitalMask.toString 16
            analogMask     = frame[18]
            analogMaskStr  = analogMask.toString 16
            if digitalMask > 0 
              digitalData = frame[19] * 256 + frame[20]
              analogOfs = 21
            else
              digitalData = 0
              analogOfs = 19
            digitalDataStr = digitalData.toString 16
            analogData = []
            while analogOfs < frameLen - 1
              analogData.push frame[analogOfs++] * 256 + frame[analogOfs++]
            log 'IO-rx', {netAddr: netAddrStr, srcAddr: srcAddrStr, rxOptions,    \
                          digitalMask: digitalMaskStr, analogMask: analogMaskStr, \
                          digitalData: digitalDataStr, analogData}
                        
          when 0x91 # explicit Rx
            srcAddr = addr64 frame, 4
            srcAddrStr = srcAddr.toString 16
            netAddr = frame[12] * 256 + frame[13]
            netAddrStr = netAddr.toString 16
            srcEndpoint = frame[14]
            dstEndpoint = frame[15]
            clusterId = frame[16] * 256 + frame[17]
            clusterIdStr = clusterId.toString 16
            profileId = frame[18] * 256 + frame[19]
            profileIdStr = profileId.toString 16
            rxOptions = switch frame[20]
              when 0x01 then 'ACK'
              when 0x02 then 'BDCST'
              when 0x20 then 'APS'
            transSeq = frame[21]
            rxData = frame.slice 22, -1
            log 'EX-rx', {netAddr: netAddrStr, srcAddr: srcAddrStr,         \
                          clusterId: clusterIdStr, profileId: profileIdStr, \
                          transSeq, srcEndpoint, dstEndpoint, rxOptions}, 
                        '\n', dec2hex rxData
            
          when 0x88  # AT Command ResponseFrame
            frameId = frame[4]
            ATcmd = String.fromCharCode(frame[5]) + String.fromCharCode(frame[6])
            status = ['OK', 'Error', 'Invalid Command',
                            'Invalid Parameter', 'Tx Failure'][frame[7]]
            netAddr = frame[8] * 256 + frame[9]
            netAddrStr = netAddr.toString 16
            srcAddr = addr64 frame, 10
            srcAddrStr = srcAddr.toString 16
            rxData = frame.slice 18, -1
            log 'AT-rx', {frameId, ATcmd, status, \
                          netAddr: netAddrStr, srcAddr: srcAddrStr}, '\n', 
                         dec2hex rxData
                         
          when 0x8B  # Transmit Status
            frameId    = frame[4]
            dstAddr    = frame[5] * 256 + frame[6]
            dstAddrStr = dstAddr.toString 16
            retries    = frame[7] 
            deliveryStatus    = frame[8]
            deliveryStatusStr = switch deliveryStatus
              when 0x00 then 'Success'
              when 0x01 then 'MAC ACK Failure'
              when 0x02 then 'CCA Failure'
              when 0x15 then 'Invalid destination endpoint'
              when 0x21 then 'Network ACK Failure'
              when 0x22 then 'Not Joined to Network'
              when 0x23 then 'Self-addressed'
              when 0x24 then 'Address Not Found'
              when 0x25 then 'Route Not Found'
              when 0x26 then 'Broadcast source failed to hear a neighbor relay the message'
              when 0x2B then 'Invalid binding table index'
              when 0x2C then 'Resource error lack of free buffers, timers, etc.'
              when 0x2D then 'Attempted broadcast with APS transmission'
              when 0x2E then 'Attempted unicast with APS transmission, but EE=0'
              when 0x32 then 'Resource error lack of free buffers, timers, etc.'
              when 0x74 then 'Data payload too large'
              when 0x75 then 'Indirect message unrequested'
            discoveryStatus    = frame[9]
            discoveryStatusStr = switch discoveryStatus
              when 0x00 then 'No Discovery Overhead'
              when 0x01 then 'Address Discovery'
              when 0x02 then 'Route Discovery'
              when 0x03 then 'Address and Route'
              when 0x40 then 'Extended Timeout Discovery'
            log 'TS-rx\n', {frameId, dstAddr: dstAddrStr, retries, \
                            deliveryStatus:  deliveryStatusStr,    \
                            discoveryStatus: discoveryStatusStr}
                            
          else
            log '??-rx\n', dec2hex frame
    else
      break

  # for index in [0..frameBuf.length-4]
  #   if (frameLen = getFrameLen index)
  #     frameBuf.splice 0, index
  #     break

write = (dataArr, cb) ->
  # log 'write', dec2hex dataArr
  dataLen = dataArr.length
  buf = new Buffer 4 + dataLen
  buf.writeUInt8 0x7E, 0
  buf.writeUInt16BE dataLen, 1
  cksum = 0
  for byte, idx in dataArr
    buf.writeUInt8 byte, 3 + idx
    cksum += byte
  buf.writeUInt8 0xFF - (cksum & 0xFF), 3 + dataLen
  # log 'write frame', buf.length, '\n', buf
  # return
  
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

explicit = (params, cb) ->
  {frameId, addr, netAddr, srcEndpoint, dstEndpoint, \
   clusterId, profileId, bdcstRadius, xOptions, payload} = params
  netAddr     ?= 0xFFFE
  bdcstRadius ?= 0
  xOptions    ?= 0
  srcEndpoint ?= 0xE8 # digi
  dstEndpoint ?= 0xE8 # digi
  if typeof payload is 'string'
    payloadStr = payload
    payload = []
    for idx in [0...payloadStr.length]
      payload.push payloadStr.charCodeAt idx
  writeData = [0x11, frameId].concat dec2arr(addr,8), dec2arr(netAddr,2),  
                srcEndpoint, dstEndpoint, 
                dec2arr(clusterId,2), dec2arr(profileId,2), 
                bdcstRadius, xOptions, payload
  write writeData, cb

zdo = (opts, cb) ->
  opts.srcEndpoint = opts.dstEndpoint = opts.profileId = 0
  opts.payload.unshift 1 # Transaction Sequence Number
  explicit opts, cb
  
xbeeSerialPort.on 'error', (err) -> log 'xbeeSerialPort err', err

xbeeSerialPort.on 'open', ->
  log 'Port open'
  xbeeSerialPort.on 'data', assembleFrame
  
  # discovery()
  
  zdo 
    frameId:     1
    addr:        0x000000000000FFFF # broadcast
    clusterId:   5 # Active Endpoints Request
    payload:     dec2arrLE 0x3DD1, 2
    # payload:     dec2arrLE(0x7CE52400001465BD, 8).concat [0,0]

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

