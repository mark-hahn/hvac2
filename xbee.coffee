
{log, logObj} = require('./js/utils') ' XBEE'
log 'starting xbee'

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
  
arr2hexLE = (arr, start=0, end=arr.length) ->
  hex = ''
  for idx in [start...end]
    hexByteVal = arr[idx].toString 16
    hexByte = (if hexByteVal.length < 2 then '0' else '') + hexByteVal
    hex = hexByte + hex
  hex
  
hex2arr = (hex, len) ->
  while hex.length < len * 2 then hex = '0' + hex
  arr = []
  for i in [1..len]
    arr.push parseInt hex[0..1], 16
    hex = hex[2...]
  arr

hex2arrLE = (hex, len) ->
  while hex.length < len * 2 then hex = '0' + hex
  arr = []
  for i in [1..len]
    arr.unshift parseInt hex[0..1], 16
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
  # log 'IO-data', ioData
  emitSrc.emit 'ioData', srcAddr, ioData 
  
  
################ RECEIVE frame ################
statusByCode = (code) ->
  ['OK', 'Error', 'Invalid Command',
                  'Invalid Parameter', 'Tx Failure'][code]
newFrame = (frame) ->
  # log 'newFrame\n', dumpArrAsHex frame
  # return
  
  switch frame[3] # type
    when 0x88  # AT Command ResponseFrame
      frameId = frame[4]
      ATcmd = String.fromCharCode(frame[5]) + String.fromCharCode(frame[6])
      status = statusByCode frame[7]
      if ATcmd is 'ND'
        netAddr = frame[8] * 256 + frame[9]
        netAddrStr = netAddr.toString 16
        srcAddr = arr2hex frame, 10, 18
        log 'AT-rx-ND', {frameId, ATcmd, status, netAddr: netAddrStr, srcAddr}
        return
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
      # log 'TS-rx\n', {frameId, dstAddr: dstAddrStr, retries, \
                      # deliveryStatus:  deliveryStatusStr,    \
                      # discoveryStatus: discoveryStatusStr}

    when 0x91 # explicit Rx
      # log 'explicit Rx frame\n', dumpArrAsHex frame
      srcAddr = arr2hex frame, 4, 12
      netAddr = frame[12] * 256 + frame[13]
      netAddrStr = arr2hex frame, 12, 14
      srcEndpoint = frame[14]
      srcEndpointStr = srcEndpoint.toString 16
      dstEndpoint = frame[15]
      dstEndpointStr = dstEndpoint.toString 16
      clusterId = frame[16] * 256 + frame[17]
      clusterIdStr = arr2hex frame, 16, 18
      profileId = frame[18] * 256 + frame[19]
      profileIdStr = arr2hex frame, 18, 20
      rxOptions = frame[20]
      rxOptionsArr = []
      if rxOptions & 0x01 then rxOptionsArr.push 'ACK'
      if rxOptions & 0x02 then rxOptionsArr.push 'BDCST'
      if rxOptions & 0x20 then rxOptionsArr.push 'APS'
      if rxOptions & 0x40 then rxOptionsArr.push 'EXTTO'
      rxOptionsStr = rxOptionsArr.join ' '
      transSeq = frame[21]
      rxFields = {
        srcAddr, netAddr: netAddrStr
        clusterId: clusterIdStr, profileId: profileIdStr
        transSeq
        srcEndpoint: srcEndpointStr
        dstEndpoint: dstEndpointStr
        rxOptions: rxOptionsStr
      }
      rxData = frame[22...]
      switch clusterId
        when 0x0092
          # log 'EX-rx-io', rxFields
          # if srcAddr is '0013a20040baffad'
          #   log 'EX-rx-io', srcAddr + ', ' + netAddr + ', ' + profileIdStr + ', ' + 
          #                   srcEndpointStr + ', ' + dstEndpointStr + ', ' + rxOptionsStr
          recvIO srcAddr, rxData
        when 0x8031
          startIdx   = rxData[2]
          numEntries = rxData[3]
          log 'EX-rx-LQI', rxFields, {
            status: statusByCode rxData[0]
            totalEntryCount: rxData[1]
            startIdx, numEntries
          }
          for i in [0...numEntries]
            entry = rxData[4+i*22...4+(i+1)*22]
            extPan  = arr2hexLE entry[0.. 7]
            extAddr = arr2hexLE entry[8..15]
            netAddr = arr2hexLE entry[16..17]
            bits    = arr2hexLE entry[18..19]
            depth   = entry[20]
            LQI     = entry[21]
            log 'LQI(' + (startIdx + i) + ')', {extPan, extAddr, netAddr, bits, depth, LQI}
        # else
          # log 'EX-rx other', rxFields, dumpArrAsHex rxData
      
    when 0x92  #  IO Data Sample Rx
      srcAddr = arr2hex frame, 4, 12
      netAddr = frame[12] * 256 + frame[13]
      netAddrStr = netAddr.toString 16
      rxOptions = switch frame[14]
        when 0x01 then 'ACK'
        when 0x02 then 'BDCST'
      # numSamples = frame[15] --> always 1
      # log 'IO-rx', {netAddr: netAddrStr, srcAddr, rxOptions}
      recvIO srcAddr, frame[16...]
                                              
    else
      log 'unknown frame type\n', dumpArrAsHex frame
  
  
################ BUILD recv frame ################

frameBuf = frameLen = discardByte = null
discardCount = 0
inEscape = no

newBytes = (buf) ->
  # log 'recv data', buf
  for bufIdx in [0...buf.length]
    byte = buf[bufIdx]
    if not frameBuf
      do chkDiscard = ->
        # if discardCount and byte isnt discardByte
        #   log '>>> discarded byte', dumpArrAsHex([discardByte]) + 
        #       (if discardCount > 1 then ' (' + discardCount + ')' else '')
        #   discardCount = 0
      if byte is 0x7E
        chkDiscard()
        frameBuf = [0x7E]
      else 
        discardCount++
        discardByte = byte
      continue
    if inEscape
      byte ^= 0x20
      inEscape = no
    else if byte is 0x7D
      inEscape = yes
      continue
    frameBuf.push byte
    if not frameLen and frameBuf.length is 3
      frameLen = frameBuf[1] * 256 + frameBuf[2]
    # log 'new byte', {byte: dumpArrAsHex([byte]), frameLen, \
                    #  frameBufLen: frameBuf.length, frameBuf: dumpArrAsHex frameBuf}
    if frameLen and frameBuf.length is frameLen + 4
      cksum = 0
      for byte in frameBuf[3...-1] then cksum += byte
      cksum &= 0xff
      if (0xff - cksum) is frameBuf[frameBuf.length-1]
        newFrame frameBuf
      else
        log 'checksum error', dumpArrAsHex frameBuf
      frameLen = null
      frameBuf = null


################ SEND ###################

send = (frame, cb) ->
  # log 'send frame', frame.length, '\n', dumpArrAsHex frame
  # return
  
  buf = new Buffer frame
  if not xbeeSerialPort.isOpen()
    log 'attempted write while closed', buf.toString()
    cb? 'attempted write while closed'
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
    
        
################ BUILD send frame ################

write = (data, cb) ->
  len = data.length
  data = [len >>> 8, len & 0xFF].concat data
  frame = [0x7E]
  cksum = 0
  for byte, idx in data
    if idx > 1 then cksum += byte
    if byte in [0x7E, 0x7D, 0x11, 0x13]
      frame.push 0x7D
      frame.push byte ^= 0x20
    else
      frame.push byte
  frame.push 0xFF - (cksum & 0xFF)
  send frame, cb
  
  
################# AT commands  ################
frameId = 0

# talk to local module
ATcmd = (cmd, data, cb) ->
  ++frameId
  if typeof data is 'function' then cb = data; data = []
  writeData = [
    0x08
    frameId
    cmd.charCodeAt(0)
    cmd.charCodeAt(1)
  ].concat data
  write writeData, cb

netDiscovery = (cb) ->     # pg 98, 203
  log '\n\n--- net discovery start\n'
  ATcmd 'ND', -> log '\n\n--- net discovery end\n'


################# Explicit (ZDO/ZCL)  ################

# send to specific app layers (endpoint and cluster ID) in remote module
explicit = (opts, cb) ->
  ++frameId
  {dstAddr, netAddr, srcEndpoint, dstEndpoint, \
   clusterId, profileId, bdcstRadius, xOptions, payload} = opts
  dstAddr     ?= '000000000000FFFF' # ...0ffff -> broadcast
  netAddr     ?= 0xFFFE             #   0xFFFE -> unknown
  srcEndpoint ?= 0xE8 # digi
  dstEndpoint ?= 0xE8 # digi
  bdcstRadius ?= 0  # max hops
  xOptions    ?= 0  # xmit bit field
  payload     ?= []
  if typeof payload is 'string'
    payloadStr = payload
    payload = []
    for idx in [0...payloadStr.length]
      payload.push payloadStr.charCodeAt idx
  # log 'explicit send', {
  #   frameId, dstAddr, 
  #   netAddr:     netAddr    .toString(16)
  #   srcEndpoint: srcEndpoint.toString(16)
  #   dstEndpoint: dstEndpoint.toString(16)
  #   clusterId:   clusterId  .toString(16)
  #   profileId:   profileId  .toString(16)
  #   bdcstRadius, xOptions, payload: dumpArrAsHex payload
  # }
  writeData = [0x11, frameId]
    .concat hex2arr(dstAddr,8), num2arr(netAddr,2),  
            srcEndpoint, dstEndpoint, 
            num2arr(clusterId,2), num2arr(profileId,2), 
            bdcstRadius, xOptions, payload
  write writeData, cb

### ZDO ###

zdo = (opts, cb) ->  # pg 173
  opts.srcEndpoint = 0  # 0 -> ZDO endpoint
  opts.dstEndpoint = 0  # 0 -> ZDO endpoint
  opts.profileId   = 0  # Zigbee Device Profile,  0 -> ZDO
  opts.payload ?= []
  opts.payload.unshift 1 # Transaction Sequence Number
  explicit opts, cb

activeEnds = (netAddr) -> # example: active endpoints
  zdo
    clusterId: 5  # Active Endpoints Request
    payload:   num2arrLE netAddr, 2

nar = (dstAddr) -> # example: net addr req
  zdo 
    clusterId: 0 
    payload:  hex2arrLE(dstAddr, 8).concat [0,0]
    
lqi = (addr, ofs) ->  # pg 99
  zdo                        
    clusterId: 0x0031
    dstAddr:   addr
    payload:   [ofs]

### ZCL ###

zcl = (opts, cb) ->  # pg 175
  zclTransSeq = 1
  zclFrameHdr = [opts.zclFrameCtl, zclTransSeq, opts.zclCmdId]
  opts.payload = zclFrameHdr.concat opts.zclPayload
  delete opts.zclFrameCtl
  delete opts.zclCmdId
  delete opts.zclPayload
  explicit opts, cb

hwv = ->    # example: read hardware version attr
  zcl
    dstAddr:    'e20db9fffe0232bd'  # cree
    netAddr:     0xbd7a             # cree
    srcEndpoint: 0xe8 
    dstEndpoint: 0x0a
    clusterId:   0       #                           0 -> basic 
    profileId:   0x0104  #                         104 -> HA
    zclFrameCtl: 0       # bit field, see docs,      8 -> server to client
    zclCmdId:    0       # zcl command               0 -> read attrs
    zclPayload:  num2arrLE(3, 2) # attr ids,         3 -> hw vers

onOff = (dstAddr, netAddr, action='toggle') ->
  zclCmdId = switch action
    when 'off'    then 0
    when 'on'     then 1
    when 'toggle' then 2
  dstEndpoint = switch dstAddr[0..7]
    when '0013a200' then 0x0a  # xbee
    when 'e20db9ff' then 0x0a  # cree
    when '7ce52400' then 0x01  # ge
  zcl {
    dstAddr, netAddr, zclCmdId, dstEndpoint
    srcEndpoint: 0xe8 
    clusterId:   6          #                           6 -> on/off 
    profileId:   0x0104     #                         104 -> HA
    zclFrameCtl: 1          # bit field, see docs,      1 -> Cluster Specific
    zclPayload:  []
  }

allOnOff = (action='toggle') ->
  onOff '7ce5240000116393', 0x31bd, action  # no response
  onOff '7ce524000013c315', 0x32c0, action
  onOff '7ce5240000116ccc', 0x823d, action
  onOff '7ce52400001465bd', 0x096d, action
  onOff '7ce5240000124e6f', 0xfcba, action
  onOff '7ce524000013c38c', 0xda60, action

# endpoints e6 and e8 found in all xbees
# pg 179 -> Public Profile Commands

################# TESTING #################


setTimeout ->
  allOnOff process.argv[2]
  # netDiscovery()   # xbee modules only
  # activeEnds 0x0000  # controller
  # activeEnds 0xe622
  # nar '7ce524000013c315'
  # setTimeout (-> lqi '7ce5240000116393', 0), 1000
  # setTimeout (-> lqi '7ce5240000116393', 1), 2000
  # setTimeout (-> lqi '7ce5240000116393', 2), 3000
  # setTimeout (-> lqi '7ce5240000116393', 3), 4000
  # setTimeout (-> lqi '7ce5240000116393', 4), 5000
  # setTimeout (-> lqi '7ce5240000116393', 5), 6000
  # setTimeout (-> lqi '7ce5240000116393', 6), 7000
  # setTimeout (-> lqi '7ce5240000116393', 7), 8000
  # setTimeout (-> lqi '7ce5240000116393', 8), 9000
  # setTimeout (-> lqi '7ce5240000116393', 9), 10000
  # setTimeout (-> lqi '7ce5240000116393', 10), 11000
  # setTimeout (-> lqi '7ce5240000116393', 11), 12000
  # hwv()   # ZCL
  # allOnOff 'on'
  # onOff '7ce5240000116393', 0x31bd, 'on'  # no response
  # onOff '7ce524000013c315', 0x32c0, 'on'
  # onOff '7ce5240000116ccc', 0x823d, 'on'
  setTimeout (-> xbeeSerialPort.close()), 1000
, 1000


################# SERIAL events #################

xbeeSerialPort.on 'error', (err) -> log 'xbee port err', err

xbeeSerialPort.on 'open', ->
  log 'port open'
  xbeeSerialPort.on 'data', newBytes
  
  
################# NOTES #################
###
  tvRoom : '0013a20040baffad'
  kitchen: '0013a20040b3a592'

  frameCtl = 0  # Bitfield that defines the command type
  transSeq = 1
  cmdId    = 0  #  Since the frame control “frame type” bits 
                #  are 00, this byte specifies a general command.
                #  Command ID 0x00 is a Read Attributes command
  zcl 0, # basic cluster
    frameId:     1
    dstAddr:       '0013A20040401234'   # arbitrary
    srcEndpoint: 0x41                # arbitrary
    dstEndpoint: 0x42                # arbitrary
    profileId:   0xD123              # arbitrary
    bdcstRadius: 0                   # max hops
    
    zclFrameHdr: [frameCtl, transSeq, cmdId]  # payload always in LE order
    zclPayload:   num2arrLE 0x0003, 2           # attrId 

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

###
Management Network Discovery Request
Cluster ID:  0x0030
Description:  Unicast transmission used to cause a remote device to 
              perform a network scan (to discover nearby networks).

  Scan Channels (4 bytes)  Bitmap indicating the channel mask that should be scanned. 
                          Examples (big endian byte order):
                            Channel 0x0B = 0x800
                            All Channels (0x0B –0x1A) = 0x07FFF800
  Scan Duration (1 byte) Time to scan on each channel
  Start Index   (1 byte) 1Start index in the resulting network list.

cree e20db9fffe0232bd  # bd7a (6)

ge   7ce5240000116393  # 31bd  ( ) light tv room front left
ge   7ce524000013c315  # 32c0  (8) light tv room front middle
ge   7ce5240000116ccc  # 823d  (3) light tv room front right
ge   7ce52400001465bd  # 096d  (0) light tv room back left
ge   7ce5240000124e6f  # fcba  (9) light tv room back middle
ge   7ce524000013c38c  # da60  (7) light tv room back right  

###