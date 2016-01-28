
# 7CE52400001465BD

{log, logObj} = require('./js/utils') ' XBEE'

SerialPort = require('serialport').SerialPort
emitSrc = new (require('events').EventEmitter)
  
xbeeSerialPort = new SerialPort '/dev/xbee',
  baudrate: 9600,
  databits: 8,
  stopbits: 1,
  parity: 0,
  flowcontrol: 0,

################## DATA utils ######################

dumpArrAsHex = (arr) ->
  hexArr = []
  for byte in arr
    hex = byte.toString 16
    if hex.length < 2 then hex = '0' + hex
    hexArr.push hex
  hexArr.join ' '

arr2num = (arr, start=0, end=arr.length) ->
  num = 0
  for i in [start...end]
    num *= 256
    num += arr[i]
  num
    
num2arr = (dec, len) ->
  arr = []
  for i in [1..len]
    arr.unshift (dec & 0xFF)
    dec >>>= 8
  arr
  
num2arrLE = (dec, len) ->
  arr = []
  for i in [1..len]
    arr.push (dec & 0xFF)
    dec >>>= 8
    arr

arr2hex = (arr, start=0, end=arr.length) ->
  hex = ''
  for idx in [start...end]
    hexByteVal = arr[idx].toString 16
    hexByte = (if hexByteVal.length < 2 then '0' else '') + hexByteVal
    hex += hexByte
  hex
  
hex2arr = (hex, len) ->
  while hex.length < len * 2 then hex = '0' + hex
  arr = []
  for i in [1..len]
    arr.push parseInt hex[0..1], 16
    hex = hex[2...]
  arr


################ IO data ################

recvIO = (srcAddr, frame) ->
  digitalMask    = frame[0] * 256 + frame[1]
  digitalMaskStr = digitalMask.toString 16
  analogMask     = frame[2]
  analogMaskStr  = analogMask.toString 16
  if digitalMask > 0 
    digitalData = frame[3] * 256 + frame[4]
    analogOfs = 5
  else
    digitalData = 0
    analogOfs = 3
  digitalDataStr = digitalData.toString 16
  analogData = []
  while analogOfs < frame.length - 1
    analogData.push frame[analogOfs++] * 256 + frame[analogOfs++]
  ioData = {digitalMask: digitalMaskStr, analogMask: analogMaskStr, \
            digitalData: digitalDataStr, analogData}
  log 'IO-data', ioData
  emitSrc.emit 'ioData', srcAddr, ioData 
  
  
################ RECEIVE frame ################

newFrame = (frame) ->
  # log 'newFrame\n', dumpArrAsHex frame
  # return
  
  cksum = 0
  for byte in frame[3...-1] then cksum += byte
  cksum &= 0xff
  if (0xff - cksum) isnt frame[frame.length-1]
    log 'checksum error', dumpArrAsHex frame
    return
      
  switch frame[3] # type
    when 0x88  # AT Command ResponseFrame
      frameId = frame[4]
      ATcmd = String.fromCharCode(frame[5]) + String.fromCharCode(frame[6])
      status = ['OK', 'Error', 'Invalid Command',
                      'Invalid Parameter', 'Tx Failure'][frame[7]]
      # netAddr = frame[8] * 256 + frame[9]
      # netAddrStr = netAddr.toString 16
      # srcAddr = arr2hex frame, 10, 18
      cmdData = (if frameId is 0 then [] else frame.slice 8, -1)
      log 'AT-rx', {frameId, ATcmd, status, \
                    netAddr: netAddrStr, srcAddr}, '\n', dumpArrAsHex cmdData
                   
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

    when 0x91 # explicit Rx
      srcAddr = arr2hex frame, 4, 12
      netAddr = frame[12] * 256 + frame[13]
      netAddrStr = netAddr.toString 16
      srcEndpoint = frame[14]
      dstEndpoint = frame[15]
      clusterId = frame[16] * 256 + frame[17]
      clusterIdStr = clusterId.toString 16
      profileId = frame[18] * 256 + frame[19]
      profileIdStr = profileId.toString 16
      rxOptions = frame[20]
      rxOptionsArr = []
      if rxOptions & 0x01 then rxOptionsArr.push 'ACK'
      if rxOptions & 0x02 then rxOptionsArr.push 'BDCST'
      if rxOptions & 0x20 then rxOptionsArr.push 'APS'
      if rxOptions & 0x40 then rxOptionsArr.push 'EXTTO'
      rxOptionsStr = rxOptionsArr.join ' '
      transSeq = frame[21]
      if clusterId is 0x0092
        log 'EX-rx-io', {netAddr: netAddrStr, srcAddr, profileId: profileIdStr, \
                         transSeq, srcEndpoint, dstEndpoint, rxOptions: rxOptionsStr}
        recvIO srcAddr, frame[22...]
        return
      rxData = [22...]
      log 'EX-rx', {netAddr: netAddrStr, srcAddr,                     \
                    clusterId: clusterIdStr, profileId: profileIdStr, \
                    transSeq, srcEndpoint, dstEndpoint, rxOptions: rxOptionsStr}, 
                  '\n', dumpArrAsHex rxData
      
    when 0x92  #  IO Data Sample Rx
      srcAddr = arr2hex frame, 4, 12
      netAddr = frame[12] * 256 + frame[13]
      netAddrStr = netAddr.toString 16
      rxOptions = switch frame[14]
        when 0x01 then 'ACK'
        when 0x02 then 'BDCST'
      # numSamples = frame[15] --> always 1
      log 'IO-rx', {netAddr: netAddrStr, srcAddr, rxOptions}
      recvIO srcAddr, frame[16...]
                                              
    else
      log 'unknown frame type\n', dumpArrAsHex frame
  
  
################ BUILD frame ################

frameBuf = frameLen = null
inEscape = pastDiscardedZeros = no

newBytes = (data) ->
  # log 'recv data', data
  
  for byte in data
    if not frameBuf
      if byte is 0x7E then frameBuf = [0x7E]
      else 
        if pastDiscardedZeros or byte isnt 0
          pastDiscardedZeros = yes
          log 'discarding input byte', dumpArrAsHex [byte]
      continue
    else
      if inEscape
        byte ^= 0x20
        inEscape = no
      else if byte is 0x7D
        inEscape = yes
        continue
    frameBuf.push byte
    if not frameLen and frameBuf.length is 3
      frameLen = frameBuf[1] * 256 + frameBuf[2]
      continue
    # log 'new byte', {byte, inEscape, frameLen, frameBufLen: frameBuf.length, frameBuf: dumpArrAsHex frameBuf}
    if frameLen and frameBuf.length is frameLen + 4
      newFrame frameBuf
      frameLen = null
      frameBuf = null


################ SEND ###################

write = (dataArr, cb) ->
  # log 'write', dumpArrAsHex dataArr
  dataLen = dataArr.length
  buf = new Buffer 4 + dataLen
  buf.writeUInt8 0x7E, 0
  buf.writeUInt16BE dataLen, 1
  cksum = 0
  for byte, idx in dataArr
    buf.writeUInt8 byte, 3 + idx
    cksum += byte
  buf.writeUInt8 0xFF - (cksum & 0xFF), 3 + dataLen
  log 'write frame', buf.length, '\n', buf
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
        
        
############## API frames #############

# talk to local module
ATcmd = (frameId, cmd, data, cb) ->
  if typeof data is 'function' then cb = data; data = []
  writeData = [0x08, frameId, cmd.charCodeAt(0), cmd.charCodeAt(1)].concat data
  write writeData, cb

# talk to remote module
transmit = (opts, cb) ->
  {frameId, dstAddr, netAddr, bdcstRadius, xOptions, payload} = opts
  netAddr     ?= 0xFFFE
  bdcstRadius ?= 0
  xOptions    ?= 0
  if typeof payload is 'string'
    payloadStr = payload
    payload = []
    for idx in [0...payloadStr.length]
      payload.push payloadStr.charCodeAt idx
  writeData = [0x10, frameId].concat hex2arr(dstAddr,8), num2arr(netAddr,2),  
                                     bdcstRadius, xOptions, payload
  write writeData, cb

# send to specific ap layers (endpoint and cluster ID) in remote module
explicit = (opts, cb) ->
  {frameId, dstAddr, netAddr, srcEndpoint, dstEndpoint, \
   clusterId, profileId, bdcstRadius, xOptions, payload} = opts
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
  writeData = [0x11, frameId].concat hex2arr(dstAddr,8), num2arr(netAddr,2),  
                srcEndpoint, dstEndpoint, 
                num2arr(clusterId,2), num2arr(profileId,2), 
                bdcstRadius, xOptions, payload
  write writeData, cb

################# ZDO/ZCL  ################

zdo = (opts, cb) ->  # pg 173
  opts.srcEndpoint = opts.dstEndpoint = opts.profileId = 0
  opts.payload.unshift 1 # Transaction Sequence Number
  explicit opts, cb
  
zcl = (zclCmd, opts, cb) ->  # pg 175
  opts.clusterId    = zclCmd 
  opts.xOptions     = 0
  opts.zclFrameHdr ?= []
  opts.payload   = opts.zclFrameHdr.concat opts.zclPayload
  delete  opts.zclFrameHdr
  delete  opts.zclPayload
  explicit opts, cb

#  pg 177 -> zcl example

# pg 179 -> Public Profile Commands


################# Execution commands  ################

netDiscovery = (cb) ->     # pg 98, 203
  ATcmd 1, 'ND', -> log 'net discovery end'

zdoLQI = (cb) ->   # pg 99
  zcl 0x0031, 
    dstAddr:    '13a20040b3a592'
    srcEndpoint: 0x41
    dstEndpoint: 0x42
    profileId:   0xd123
    zclFrameHdr: [0,1,0] # frame ctl, transaction seq #, cmd id, pg 178
    zclPayload:  [3, 0] # Attribute ID (0x0003) in little endian 
    
# Group Table API
# ZigBee Cluster Library Groups Cluster (0x0006) with ZCL commands (pg 104)


################# SERIAL events #################

xbeeSerialPort.on 'error', (err) -> log 'xbee port err', err

xbeeSerialPort.on 'open', ->
  log 'xbee port open'
  xbeeSerialPort.on 'data', newBytes
  
  
################# TESTING #################
  
  zdo 


  # frameCtl = 0  # Bitfield that defines the command type
  # transSeq = 1
  # cmdId    = 0  #  Since the frame control “frame type” bits 
  #               #  are 00, this byte specifies a general command.
  #               #  Command ID 0x00 is a Read Attributes command
  # zcl 0, # basic cluster
  #   frameId:     1
  #   dstAddr:       '0013A20040401234'   # arbitrary
  #   srcEndpoint: 0x41                # arbitrary
  #   dstEndpoint: 0x42                # arbitrary
  #   profileId:   0xD123              # arbitrary
  #   bdcstRadius: 0                   # max hops
  #   
  #   zclFrameHdr: [frameCtl, transSeq, cmdId]  # payload always in LE order
  #   zclPayload:   num2arrLE 0x0003, 2           # attrId 


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

