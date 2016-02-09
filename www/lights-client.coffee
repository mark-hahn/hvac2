###
    lights-client.coffee
###

log = (args...) -> console.log ' LGHT:', args...

port = (if noNet then 2339 else 1339)
sendLightCmd = (bulb, cmd, val) ->
  json = JSON.stringify {bulb, cmd, val}
  url = "http://hahnca.com:#{port}/lights/ajax?json=#{json}"
  oReq = new XMLHttpRequest()
  oReq.open "GET", url
  oReq.send();







do winResize = ->
  h = window.innerHeight - 30
  w = h * (9/16) * 1.2
  document.querySelector('html').style.fontSize = (w/20) + 'px'
  style = document.querySelector('.page').style
  style.width   = w + 'px'
  style.height  = h + 'px'
  style.display = 'block'
window.onresize = winResize
