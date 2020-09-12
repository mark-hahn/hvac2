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
  setInterval ->
    if (time = moment().format 'h:mm') isnt lastTime
      $('#time').text time
      lastTime = time

      date = new Date()
      times = SunCalc.getTimes(date, 33.84, -118.18639)
      riseMins = times.sunrise.getHours() * 60 + times.sunrise.getMinutes();
      setMins  = times.sunset.getHours()  * 60 + times.sunset.getMinutes();
      nowMins  = date.getHours() * 60 + date.getMinutes();
      bodyElement = document.querySelector('body');
      dividerElements = document.querySelectorAll('.divider');
      if (nowMins < riseMins or nowMins > setMins)
        #night
        # console.log('it is nighttime', {riseMins, setMins, nowMins});
        bodyElement.style.color = '#444'
        dividerElements.forEach (ele) => ele.style.backgroundColor = '#444'
      else
        #day
        # console.log('it is daytime', {riseMins, setMins, nowMins, bodyElement,dividerElements})
        bodyElement.style.color = 'white'
        dividerElements.forEach (ele) => ele.style.backgroundColor = 'white'
  , 1e3
