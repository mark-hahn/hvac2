
log = (args...) -> console.log 'WSOCK:', args...

primus = Primus.connect '',
  websockets: yes
  timeout: 10e3
  reconnect:
    max:     10e3
    retries: Infinity
    factor:  1.1

primus.on 'open', (spark) ->
  log 'connected'
  
  window.primusConnected = yes

  # primus.on 'data', (data) ->
  #   log 'received', data
  #   wsRecv data
  # 
  primus.on 'error', (err) ->
    log 'ERROR:', err

  window.wsockSend = (data) ->
    data.type = 'tstat'
    log 'sent', data
    primus.write data

   # wsRecv = (master) ->
   #  for name, value of master
   #    $('#' + name).text value
