###
  src/wx-station.coffee
  polled weewx weather station db -> wx and wx.temp streams
  xbee packet stream -> filtered/rounded temp streams for each sensor
###

log = (args...) -> console.log 'WXSTA:', args...

Rx = require 'rx'
sqlite3 = require("sqlite3").verbose()

wx = outTemp: 0

db = new sqlite3.Database '/var/lib/weewx/weewx.sdb', sqlite3.OPEN_READONLY, (err) ->
  if err then log 'Error opening weewx db', err; cb? err; return
  
  setInterval ->
    db.get 'SELECT outTemp FROM archive ORDER BY dateTime DESC LIMIT 1', (err, res) ->
      if err
        log 'Error reading weewx db', err
        db.close()
        return
      wx = res
  , 4000

module.exports =
  init:  (@obs$) -> 
    @obs$.wxStation$ = 
      Rx.Observable
        .interval 4000
        .map -> wx
    
    @obs$.temp_outside$ = 
      @obs$.wxStation$
        .map (wx) -> wx.outTemp
        .distinctUntilChanged()
        .skip 1

