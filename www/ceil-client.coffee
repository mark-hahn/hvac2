###
    ceil-client.coffee
    runs in browser
    shows on master ceiling
    talks to websocket
###

log = (args) -> console.log ' CEIL:', args

$ ->
  window.ceilWsRecv = (data) ->
    if data.type is 'ceil' then log 'recv ceil', data
    for name, value of data
      $('#' + name).text value

  do tryWs = ->
    if not window.wsockSend then setTimeout tryWs, 100
    else wsockSend type: 'reqAll'

  window.bumpTemp = (dir) ->
    window.wsockSend?(
      type:     'setStatVar'
      room:     'master'
      variable: 'setpoint'
      setData:   dir
    )
