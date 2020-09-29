###
    mbtab-client.coffee
    runs in browser on projector in master bedroom
    talks to websocket
###

log = (args) -> console.log ' MBTB:', args

$ ->
  window.mbtabWsRecv = (data) ->
    if data.type is 'mbtab' then log 'recv mbtab', data
    for name, value of data
      console.log {name, value}
      $('#' + name).text value

      if name is 'tvRoom'
        ele = document.getElementById 'tvRoom'
        if data.tvRoom_under
          ele.style['text-decoration'] = "underline"
        else
          ele.style['text-decoration'] = ""

      if name is 'kitchen'
        ele = document.getElementById 'kitchen'
        if data.kitchen_under
          ele.style['text-decoration'] = "underline"
        else
          ele.style['text-decoration'] = ""

      if name is 'guest'
        ele = document.getElementById 'guest'
        if data.guest_under
          ele.style['text-decoration'] = "underline"
        else
          ele.style['text-decoration'] = ""

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
  , 1e3
