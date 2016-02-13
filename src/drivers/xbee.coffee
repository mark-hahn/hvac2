
{log} = require('./log') ' XBEE'

{noNet} = require './global'
if noNet then return
  
$ = require('imprea')()
SerialPort = require('serialport').SerialPort
emitSrc = new (require('events').EventEmitter)

$.output 'allXbeePackets'

addrForRoom = 
# server:  0x0013a20040c33695  # 0000
  tvRoom : '0013a20040b3a954'  # b229 (4)
  kitchen: '0013a20040b3a592'  # b3fb (5)
  master:  '0013a20040b3a903'  # 3f17 ()
  guest:   '0013a20040baffad'  # 16e9 (1)
  closet:  '0013a20040bd2529'  # 6bef (2)

addrsForBulb = 
  frontLeft:   ['7ce5240000116393', 0x31bd]
  frontMiddle: ['7ce524000013c315', 0x32c0]
  frontRight:  ['7ce5240000116ccc', 0x823d]
  backLeft:    ['7ce52400001465bd', 0x096d]
  backMiddle:  ['7ce5240000124e6f', 0xfcba]
  backRight:   ['7ce524000013c38c', 0xda60]

ofs = 6

tvBulbs = [
  'frontLeft'
  'frontMiddle'
  'frontRight'
  'backLeft' 
  'backMiddle'
  'backRight' 
]

module.exports =
  init: -> 
    emitSrc.on 'ioData', (srcAddr, ioData) ->
      $.allXbeePackets {srcAddr, ioData}
  
    for room, addr of addrForRoom then do (room, addr) ->
      name = 'xbeePacket_' + room
      $.output name
      emitSrc.on 'ioData', (srcAddr, ioData) ->
        if srcAddr is addr
          $[name] ioData

    initLights()
    
SerialPort = require('serialport').SerialPort
  
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
          # log '>>> discarded byte', dumpArrAsHex([discardByte]) + 
              # (if discardCount > 1 then ' (' + discardCount + ')' else '')
          # discardCount = 0
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


################# SERIAL events #################

xbeeSerialPort.on 'error', (err) -> log 'xbee port err', err

xbeeSerialPort.on 'open', ->
  log 'port open'
  xbeeSerialPort.on 'data', newBytes


################ SEND ###################
globalSeq = 0

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

# talk to local module
ATcmd = (cmd, data, cb) ->
  if typeof data is 'function' then cb = data; data = []
  writeData = [
    0x08
    ++globalSeq
    cmd.charCodeAt(0)
    cmd.charCodeAt(1)
  ].concat data
  write writeData, cb
  cb? globalSeq


################# Explicit (ZDO/ZCL)  ################

# send to specific app layers (endpoint and cluster ID) in remote module
explicit = (opts, cb) ->
  ++globalSeq
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
  #   globalSeq, dstAddr, 
  #   netAddr:     netAddr    .toString(16)
  #   srcEndpoint: srcEndpoint.toString(16)
  #   dstEndpoint: dstEndpoint.toString(16)
  #   clusterId:   clusterId  .toString(16)
  #   profileId:   profileId  .toString(16)
  #   bdcstRadius, xOptions, payload: dumpArrAsHex payload
  # }
  writeData = [0x11, globalSeq]
    .concat hex2arr(dstAddr,8), num2arr(netAddr,2),  
            srcEndpoint, dstEndpoint, 
            num2arr(clusterId,2), num2arr(profileId,2), 
            bdcstRadius, xOptions, payload
  write writeData, cb
  cb? globalSeq

zdo = (opts, cb) ->  # pg 173
  opts.srcEndpoint = 0  # 0 -> ZDO endpoint
  opts.dstEndpoint = 0  # 0 -> ZDO endpoint
  opts.profileId   = 0  # Zigbee Device Profile,  0 -> ZDO
  opts.payload ?= []
  opts.payload.unshift 1 # Transaction Sequence Number
  explicit opts, cb

zcl = (opts, cb) ->  # pg 175
  zclFrameHdr = [opts.zclFrameCtl, ++globalSeq, opts.zclCmdId]
  opts.payload = zclFrameHdr.concat opts.zclPayload
  delete opts.zclFrameCtl
  delete opts.zclCmdId
  delete opts.zclPayload
  explicit opts, cb
  cb? globalSeq


################# LIGHT COMMANDS #################
###
   zcl book 
     scenes cluster 3.7  pg 141
     on/off cluster 3.8  pg 155
     level cluster  3.10 pg 160
###

lightCtrl = (dstAddr, netAddr, cmd, val) ->
  clusterId  = 8 # level
  time       = num2arrLE (val.time ? 1), 2
  upDown     = (if val.upDown is 'up' then 0 else 1)
  zclPayload = []
  switch cmd
    when 'onOff' 
      clusterId = 6  # onOff
      zclCmdId = switch val.action
        when 'off'    then 0
        when 'on'     then 1
        when 'toggle' then 2
    when 'moveTo'
      zclCmdId = 4
      zclPayload = [val.level].concat time
    when 'moveToLimit'
      zclCmdId = 5
      zclPayload = [upDown, val.rate]  # (steps per second)
    when 'step'
      zclCmdId = 6
      zclPayload = [upDown, val.size].concat time
    when 'stop'
      zclCmdId = 3
  if val.noOnOff then zclCmdId -= 4
    
  dstEndpoint = switch dstAddr[0..7]
    when '0013a200' then 0x0a  # xbee
    when 'e20db9ff' then 0x0a  # cree
    when '7ce52400' then 0x01  # ge
  zcl {
    dstAddr, netAddr, clusterId, zclCmdId, dstEndpoint, zclPayload
    srcEndpoint: 0xe8       # zigbee
    profileId:   0x0104     # 104 -> HA
    zclFrameCtl: 1          #   1 -> Cluster Specific
  }

initLights = ->
  $.react 'light_cmd', ->
    {bulb, cmd, val} = $.light_cmd
    if bulb not in tvBulbs and bulb isnt 'tvall' then return
    if bulb is 'tvall'
      for bulb in tvBulbs
        addrs = addrsForBulb[bulb]
        lightCtrl addrs[0], addrs[1], cmd, val
      return
    addrs = addrsForBulb[bulb]
    if not addrs
      log 'no addrs', $.light_cmd
      return
    lightCtrl addrs[0], addrs[1], cmd, val
    
    
################# TESTING #################

netDiscovery = (cb) ->     # pg 98, 203
  log '\n\n--- net discovery start\n'
  ATcmd 'ND', -> log '\n\n--- net discovery end\n'

lqi = (addr, ofs) ->  # pg 99
  zdo                        
    clusterId: 0x0031
    dstAddr:   addr
    payload:   [ofs]

activeEnds = (netAddr) -> # example: active endpoints
  zdo
    clusterId: 5  # Active Endpoints Request
    payload:   num2arrLE netAddr, 2

nar = (dstAddr) -> # example: net addr req
  zdo 
    clusterId: 0 
    payload:  hex2arrLE(dstAddr, 8).concat [0,0]
    
hwv = ->    # example: read hardware version attr
  zcl
    dstAddr:    'e20db9fffe0232bd'  # cree
    netAddr:     0xbd7a             # cree
    srcEndpoint: 0xe8 
    dstEndpoint: 0x0a
    clusterId:   0       #                           0 -> basic 
    profileId:   0x0104  #                         104 -> HA
    zclFrameCtl: 0       # bit field
    zclCmdId:    0       # zcl command               0 -> read attrs
    zclPayload:  num2arrLE(3, 2) # attr ids,         3 -> hw vers

setTimeout ->
  # lqi '0013a20040b3a903', ofs
  activeEnds 0x4f19
, 2000

