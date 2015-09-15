###
    ceil-client.coffee
    runs in browser
    shows on master ceiling
    talks to websocket
###

log = (args...) -> console.log ' CEIL:', args...

$ ->
  window.ceilWsRecv = (data) ->
    if data.type is 'ceil' then log 'recv ceil', data
    for name, value of data
      $('#' + name).text value
      
  do tryWs = ->
    if not window.wsockSend then setTimeout tryWs, 100
    else wsockSend type: 'reqAll'
      
  lastTime = ''
  setInterval ->
    if (time = moment().format 'h:mm') isnt lastTime
      $('#time').text time
      lastTime = time
  , 1e3
