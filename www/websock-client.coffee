
log = (args) -> console.log 'WSOCK:', args

primus = Primus.connect 'http://hahnca.com/hvca/',
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
    if window.wsockRecv   and data.type isnt 'tvtab'  and data.type isnt 'mbtab'
      wsockRecv data
    if window.tvtabWsRecv and data.type is 'tvtab'
      tvtabWsRecv data
    if window.mbtabWsRecv and data.type is 'mbtab'
      mbtabWsRecv data

  primus.on 'error', (err) ->
    log 'ERROR:', err

  window.wsockSend = (data) ->
    # log 'sent', data
    primus.write data
