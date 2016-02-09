###
    lights-client.coffee
###

log = (args...) -> console.log ' CEIL:', args...

do winResize = ->
  h = window.innerHeight - 30
  w = h * (9/16) * 1.15
  style = document.querySelector('.page').style
  style.width   = w + 'px'
  style.height  = h + 'px'
  style.display = 'block'
window.onresize = winResize
