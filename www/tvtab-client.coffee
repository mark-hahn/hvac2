###
    tvtab-client.coffee
    runs in browser
    shows on tv room laptop
    talks to websocket
###

log = (args) -> console.log ' TVTB:', args

$ ->
  window.tvtabWsRecv = (data) ->
    if data.type is 'tvtab' then log 'recv tvtab', data
    for name, value of data
      # console.log {name, value}
      $('#' + name).text value

  do tryWs = ->
    if not window.wsockSend then setTimeout tryWs, 100
    else wsockSend type: 'reqAll'

  lastTime = ''
  autoSetTvRoom = false
  setInterval ->
    date = new Date()

    if (time = moment(date).format 'h:mm') isnt lastTime
      $('#time').text time
      $('#date').text moment(date).format 'ddd M/D'

      lastTime = time
      if (new Date().getHours()) is 7
        if not autoSetTvRoom
          autoSetTvRoom = true
          window.wsockSend?(
            type:       'setStatVar'
            room:       'tvRoom'
            variable:   'setpoint'
            setHeatAbs:  true
            setData:     71
          )
      else
        autoSetTvRoom = false
  , 1e3
