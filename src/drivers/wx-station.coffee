###
  src/wx-station.coffee
  polled weewx weather station db -> wx and wx.temp streams
  xbee packet stream -> filtered/rounded temp streams for each sensor
###

{log, logObj} = require('./utils') 'WXSTA'

$       = require('imprea') 'wxsta'
sqlite3 = require("sqlite3").verbose()

$.output 'temp_outside'

db = new sqlite3.Database '/var/lib/weewx/weewx.sdb', sqlite3.OPEN_READONLY, (err) ->
  if err then log 'Error opening weewx db', err; cb? err; return
  
  setInterval ->
    db.get 'SELECT outTemp FROM archive ORDER BY dateTime DESC LIMIT 1', (err, res) ->
      if err
        log 'Error reading weewx db', err
        db.close()
        return
      $.temp_outside res.outTemp
  , 4000
