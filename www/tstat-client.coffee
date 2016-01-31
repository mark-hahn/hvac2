###
    tstat-client.coffee
    runs in browser
    thermostat ui for all rooms
    talks to websocket
###

log = (args...) -> console.log 'TSTAT:', args...
 
updateMS  = 10000
delayMS   = 0
blinkMS   = 200
    
curRoom = localStorage?.getItem('room') ? 'tvRoom'
# rooms   = ['tvRoom', 'Sewing', 'master', 'guest']

modes     = tvRoom: 'off', kitchen: 'off', master:'off', guest: 'off'
fans      = tvRoom:  off,  kitchen:  off,  master: off,  guest: off
qcs       = tvRoom:  off,  kitchen:  off,  master: off,  guest: off
setpoints = tvRoom: 70,    kitchen: 70,    master: 70,   guest: 70
temps     = {}
codes     = {}

$ ->
  $top       = $ '.top'
  $lftTemp   = $ '#lftTemp'
  $rgtTemp   = $ '#rgtTemp'
  $bot       = $ '.bot'
  
  window.update = (sendData = yes)->
    if curRoom is 'kitchen' then qcs.kitchen = (modes[curRoom] isnt 'off')
    $top.css border:'none', backgroundColor: '#aaa', color: 'gray'
    $('#'+curRoom).css border:'1px solid black', backgroundColor: 'yellow', color: 'black'
    $lftTemp.text (if temps[curRoom] then (+temps[curRoom]).toFixed 1 else '')
    $('#codes').text codes[curRoom]
    $rgtTemp.text setpoints[curRoom].toFixed 1
    
    maxTemp = 80
    minTemp = 65
    set = Math.min maxTemp, Math.max minTemp, setpoints[curRoom]
    red = (((set-minTemp) / (maxTemp-minTemp)) * 256).toString(16).split('.')[0]
    while red.length < 2 then red = '0' + red
    blu = ((1 - (set-minTemp) / 10) * 256).toString(16).split('.')[0]
    while blu.length < 2 then blu = '0' + red
    $rgtTemp.css color: '#' + red + '00' + blu
    
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

    if qcs[curRoom] 
      $('#qc').css
        border:'1px solid black'
        backgroundColor: '#8f8'
        color: 'black'
    
    if sendData
      wsockSend
        type:     'tstat'
        room:     curRoom
        fan:      fans[curRoom]
        mode:     modes[curRoom]
        qc:       qcs[curRoom]
        setpoint: setpoints[curRoom]
      
  $top.click (e) ->
    $tgt = $ e.target
    room = $tgt.attr 'room'
    localStorage?.setItem 'room', room
    if curRoom isnt room
      curRoom = room
      update()
      
  $bot.click (e) ->
    $tgt = $ e.target
    btn = $tgt.attr 'mode'
    switch btn
      when 'off'
        modes[curRoom] = 'off'
        fans[curRoom]  = off
        qcs[curRoom]   = off
      when 'fan'
        if (fans[curRoom] = not fans[curRoom])
          if modes[curRoom] is 'off' then modes[curRoom] = 'fan'
        else
          if modes[curRoom] is 'fan' then modes[curRoom] = 'off'
      when 'qc'
        modeOn = (modes[curRoom] isnt 'off')
        qcs[curRoom] = (if modeOn then not qcs[curRoom] else off)
        if curRoom is 'kitchen' then qcs.kitchen = modeOn
      else
        modes[curRoom] = btn
    update()
    
  $('#rgtPlus').click  -> setpoints[curRoom] += 0.5; update()
  $('#rgtMinus').click -> setpoints[curRoom] -= 0.5; update()

  window.wsockRecv = (data) ->
    switch data.type
      when 'tstat'
        modes[data.room]     = data.mode
        fans[data.room]      = data.fan
        qcs[data.room]       = data.qc
        setpoints[data.room] = data.setpoint
        update no
        
      when 'temp'
        temps[data.room] = data.temp
        update no  
              
      when 'codes'
        codes[data.room] = data.codes
        update no  

