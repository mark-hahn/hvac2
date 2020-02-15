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
  lastTime = ''
  autoSetTvRoom = false
  setInterval ->
    if (time = moment().format 'h:mm') isnt lastTime
      $('#time').text time
      lastTime = time
      if (new Date().getHours()) is 7
        if not autoSetTvRoom
          autoSetTvRoom = true
          window.wsockSend?(
            type:       'setStatVar'
            room:       'tvRoom'
            variable:   'setpoint'
            setHeatAbs:  true
            setData:     70.5
          )
      else
        autoSetTvRoom = false
  , 1e3
