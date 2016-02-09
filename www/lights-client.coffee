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

bulbs = [
  'frontLeft'
  'frontMiddle'
  'frontRight' 
  'backLeft'
  'backMiddle'
  'backRight'
]

for ele, idx in document.querySelectorAll '.light'
  bulb = bulbs[idx]
  do (bulb) ->
    ele.onclick = (e) ->
      action = (if e.target.classList.contains 'topLight' then 'on' else 'off')
      sendLightCmd bulb, 'onOff', {action}

do winResize = ->
  h = window.innerHeight - 30
  w = h * (9/16) * 1.15
  document.querySelector('html').style.fontSize = (w/20) + 'px'
  style = document.querySelector('.page').style
  style.width   = w + 'px'
  style.height  = h + 'px'
  style.display = 'block'
window.onresize = winResize
