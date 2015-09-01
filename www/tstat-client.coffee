###
    tstat-client.coffee
    runs in browser
    thermostat ui for all rooms
    talks to websocket
###
 
updateMS  = 10000
delayMS   = 0
blinkMS   = 200
    
curRoom = localStorage?.getItem('room') ? 'tvRoom'
rooms   = ['tvRoom', 'kitchen', 'master', 'guest']

modes     = {tvRoom: 'off', kitchen: 'off', master:'off', guest: 'off'}
fans      = {tvRoom: off, kitchen: off, master:off, guest: off}
setpoints = {tvRoom: 70, kitchen: 70, master: 70, guest: 70}

$ ->
  $top       = $ '.top'
  $lftTemp   = $ '#lftTemp'
  $rgtTemp   = $ '#rgtTemp'
  $bot       = $ '.bot'
  $blinkEles = $rgtTemp.add($top).add($bot)
  changes    = room: curRoom
  
  window.update = ->
    $top.css border:'none', backgroundColor: '#aaa', color: 'gray'
    $('#'+curRoom).css border:'1px solid black', backgroundColor: 'yellow', color: 'black'
    $rgtTemp.text setpoints[curRoom].toFixed 1
    $bot.css 
      border:'none'
      backgroundColor: '#aaa'
      color: 'gray'
      
    if fans[curRoom] 
      $('#fan').css
        border:'1px solid black'
        backgroundColor: '#8f8'
        color: 'black'
    
    $('#'+modes[curRoom]).css 
      border:'1px solid black'
      backgroundColor: '#8f8'
      color: 'black'

    wsockSend
      type:     'tstat'
      room:     curRoom
      fan:      fans[curRoom]
      mode:     modes[curRoom]
      setpoint: setpoints[curRoom]

  do init = ->
    setTimeout ->
      if window.primusConnected
        for curRoom in rooms then update()
        curRoom = localStorage?.getItem('room') ? 'tvRoom'
        update()
      else
        init()
    , 100
      
  $top.click (e) ->
    $tgt = $ e.target
    room = $tgt.attr 'room'
    localStorage?.setItem 'room', room
    if curRoom isnt room
      curRoom = room
      update()
      
  $('#rgtPlus').click  -> setpoints[curRoom] += 0.5; update()
  $('#rgtMinus').click -> setpoints[curRoom] -= 0.5; update()

  $bot.click (e) ->
    $tgt = $ e.target
    btn = $tgt.attr 'mode'
    if btn is 'off'
      modes[curRoom] = 'off'
      fans[curRoom] = off
    else if btn is 'fan'
      fans[curRoom] = not fans[curRoom]
    else
      if modes[curRoom] is btn
        modes[curRoom] = (if fans[curRoom] then 'fan' else 'off')
      else
        modes[curRoom] = btn
      if btn is 'off' then fans[curRoom] = off
    if modes[curRoom] in ['off', 'fan']
      modes[curRoom] = (if fans[curRoom] then 'fan' else 'off')
    update()

