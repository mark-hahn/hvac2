
log = (args...) -> console.log 'WSOCK:', args...

primus = Primus.connect '',
  websockets: yes
  timeout: 10e3
  reconnect:
    max:     10e3
    retries: Infinity
    factor:  1.1

primus.on 'open', ->
  log 'connected'
  
  primus.write type: 'reqAll'

  primus.on 'data', (data) ->
    # log 'received', data
    if window.wsockRecv  and data.type isnt 'ceil'
      wsockRecv data
    if window.ceilWsRecv and data.type is 'ceil'
      ceilWsRecv data
  
  primus.on 'error', (err) ->
    log 'ERROR:', err

  window.wsockSend = (data) ->
    # log 'sent', data
    primus.write data
