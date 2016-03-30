###
    lights-client.coffee
###

log = (args...) -> console.log ' LGHT:', args...

winW = winH = lastLevel = null

bulbs = [
  'tvall'
  'frontLeft'
  'frontMiddle'
  'frontRight' 
  'backLeft'
  'backMiddle'
  'backRight'
  'deckBbq'
  'deckTable'
  'patio'
]

sendLightCmd = (bulb, cmd, val) ->
  json = JSON.stringify {bulb, cmd, val}
  url = "http://hahnca.com/lights/ajax?json=#{json}"
  oReq = new XMLHttpRequest()
  oReq.open "GET", url
  oReq.send();

dim = (bulb, pageX) ->
  dragW    = winW * 0.80
  dragOfsX = winW * 0.10
  dragX = Math.max 0, Math.min dragW, pageX - dragOfsX
  level = Math.round (dragX/dragW) * 8
  if level isnt lastLevel
    sendLightCmd bulb, 'moveTo', level: (1 << level) - 1
  lastLevel = level
  
mouseDraggingBulb = null

page = document.querySelector '.page'
page.onmousemove = (e) ->
  if not mouseDraggingBulb then return
  e.preventDefault()
  dim mouseDraggingBulb, e.pageX
page.onmouseup    = -> mouseDraggingBulb = null; lastLevel = null
page.onmouseleave = -> mouseDraggingBulb = null; lastLevel = null

dimTO = null
dimBtn = document.querySelector '.dimBtn'
dimBtn.onclick = -> 
  sendLightCmd 'patio', 'dim', {}
  if dimTO then return
  dimBtn.classList.add 'invis'
  dimTO = setTimeout ->
    if dimTO then clearTimeout dimTO
    dimTO = null
    dimBtn.classList.remove 'invis'
  , 100

TO = null
for ele, idx in document.querySelectorAll '.light'
  bulb = bulbs[idx]
  
  do (bulb) ->
    ele.onclick = (e) ->
      e.preventDefault()
      mouseDraggingBulb = null; lastLevel = null
      pageX = (if e.target.classList.contains 'topLight' then winW else 0)
      dim bulb, pageX
      if TO then return
      e.target.classList.add 'invis'
      TO = setTimeout ->
        if TO then clearTimeout TO
        TO = null
        e.target.classList.remove 'invis'
      , 100
    ele.ontouchmove = (e) ->
      e.preventDefault()
      dim bulb, e.changedTouches[0].pageX
      
    ele.onmousedown = (e) ->
      e.preventDefault()
      lastLevel = null
      mouseDraggingBulb = bulb
      
do winResize = ->
  winH = window.innerHeight - 30
  winW = winH * (9/16) * 1.15
  document.querySelector('html').style.fontSize = (winW/20) + 'px'
  style = document.querySelector('.page').style
  style.width   = winW + 'px'
  style.height  = winH + 'px'
  style.display = 'block'
window.onresize = winResize
