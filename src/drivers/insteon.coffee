###
  src/drivers/insteon.coffee
  timing dampers/hvac in -> insteon relays in closet
###

log    = (args...) -> console.log 'INSTE:', args...
logobj = (title, obj) -> log require('./utils').fmtobj title, obj

Rx       = require 'rx'
request  = require 'request'

insteonHubAddr        = 'http://192.168.1.103:1342/io/set/'
hvacInsteonAddress    = '387EFD'
dampersInsteonAddress = '387B9E'

hvacInsteonHubUrlPfx    = insteonHubAddr + hvacInsteonAddress    + '/'
dampersInsteonHubUrlPfx = insteonHubAddr + dampersInsteonAddress + '/'

send = (isDamper, obj, cb) ->
  logobj 'send ' + (if isDamper then 'damp' else 'hvac'), obj
   
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
  pfx = (if isDamper then dampersInsteonHubUrlPfx  \
                     else hvacInsteonHubUrlPfx)
  # log 'request', pfx + dataHex
  request pfx + dataHex, (err, res) ->
    # log 'cmd res', {err, res: res.statusCode}
    if err
      name = (if isDamper then 'damper' else 'hvac')
      log 'cmd err', name, err; cb? err; return
    cb?()

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

module.exports =
  init: (@obs$) -> 
    
    @obs$.timing_dampers$.forEach (dampers) -> 
      # logobj 'damp in', dampers
      sendWretry yes, dampers
      
    @obs$.timing_hvac$.forEach (hvac) -> 
      # logobj 'hvac in', hvac
      sendWretry no, hvac
        
    sendWretry no,  {extAir: off, fan: off,    heat: off, cool: off}
    sendWretry yes, {tvRoom: on,  kitchen: on, master:on, guest: on}
    
    log 'relays cleared'
