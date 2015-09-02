###
  src/drivers/insteon.coffee
  timng dampers/hvac in -> insteon relays in closet
###

log      = (args...) -> console.log 'INSTE:', args...
Rx       = require 'rx'
request  = require 'request'

insteonHubAddr        = 'http://192.168.1.103:1342/io/set/'
hvacInsteonAddress    = '387EFD'
dampersInsteonAddress = '387B9E'

hvacInsteonHubUrlPfx    = insteonHubAddr + hvacInsteonAddress    + '/'
dampersInsteonHubUrlPfx = insteonHubAddr + dampersInsteonAddress + '/'

send = (isDamper, obj, cb) ->
  log 'send', {isDamper, obj}
  return
  
  data = 0
  for name, val of obj
    bit = switch name
      when 'tvRoom',  'heat'   then 1
      when 'kitchen', 'cool'   then 2
      when 'master',  'fan'    then 4
      when 'guest',   'extAir' then 8
    if isDamper and not val or not isDamper and val
      data += bit
  dataHex = data.toString 16
  # log 'dataHex', {dataHex, hvacInsteonHubUrlPfx}
  pfx = (if isDamper then dampersInsteonHubUrlPfx  \
                     else hvacInsteonHubUrlPfx)
  # log 'request pfx', pfx
  request pfx + dataHex, (err, res) ->
    # log 'insteon cmd res', {err, res}
    if err
      name = (if isDamper then 'damper' else 'hvac')
      log 'insteon cmd err', name, err; cb? err; return
    cb?()

tryTO = {}

sendWretry = (isDamper, obj) ->
  # log 'sendWretry', {isDamper, obj}
  if tryTO[''+isDamper]
    clearTimeout tryTO[''+isDamper]
    delete tryTO[''+isDamper]
    
  do tryOnce = (isDamper, obj, tries = 0) ->
    # log 'tryOnce', {isDamper, obj, tries}
    delete tryTO[''+isDamper]
    
    send isDamper, obj, (err) ->
      if err
        if ++tries > 12
          log 'giving up, too many retries of insteon command'
          return
        tryTO[''+isDamper] = setTimeout (-> tryOnce isDamper, obj, tries), 5e3

module.exports =
  init: (@obs$) -> 
    
    @obs$.timng_dampers$.forEach (dampers) -> 
      # log 'timng_dampers$ in', dampers
      sendWretry yes, dampers
      
    @obs$.timng_hvac$.forEach (hvac) -> 
      # log 'timng_hvac$ in', hvac
      sendWretry no, hvac
        
    sendWretry no,  {extAir: off, fan: off, heat: off, cool: off}
    sendWretry yes, {tvRoom: on, kitchen: on, master:on, guest: on}

    log 'relays cleared'
    
