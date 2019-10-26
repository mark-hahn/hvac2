###
  src/wx-station.coffee
  polled weewx weather station db -> wx and wx.temp streams
  xbee packet stream -> filtered/rounded temp streams for each sensor
###

{log, logObj} = require('./log') 'WXSTA'

$       = require('imprea')()
sqlite3 = require("sqlite3").verbose()

$.output 'weewx_data'

db = new sqlite3.Database '/var/lib/weewx/weewx.sdb', sqlite3.OPEN_READONLY, (err) ->
  if err then log 'Error opening weewx db', err; cb? err; return
  lastUpdate = null
  
  interval = setInterval ->
    db.get 'SELECT dateTime, outTemp, outHumidity, ' +
                  'windSpeed, windDir, windGust, windGustDir ' +
           'FROM archive ORDER BY dateTime DESC LIMIT 1', (err, data) ->
      {dateTime, outTemp, outHumidity,
       windSpeed, windDir, windGust, windGustDir} = data
      if err
        clearInterval interval
        log 'Error reading weewx db', err
        db.close()
        return
      if data.dateTime isnt lastUpdate
        lastUpdate = data.dateTime
        db.all 'SELECT dateTime, rain FROM archive WHERE dateTime > ' + 
                Math.round(Date.now()/1000 - 5 * 24 * 60 * 60), (err, rainData) ->
          if err
            clearInterval interval
            log 'Error reading weewx db rain', err
            db.close()
            return
          lastRain  = 0
          totalRain = 0
          for row in rainData
            if row.dateTime > lastRain + 2 * 24 * 60 * 60
              totalRain = 0
            if row.rain
              totalRain += row.rain
              lastRain = row.dateTime
              
          data.rain = totalRain
          $.weewx_data data
      
  , 5*1e3

###
usUnits
interval
barometer
pressure
altimeter
inTemp
outTemp
inHumidity
outHumidity
windSpeed
windDir
windGust
windGustDir
rainRate
rain
dewpoint
windchill
heatindex
ET
radiation
UV
extraTemp1
extraTemp2
extraTemp3
soilTemp1
soilTemp2
soilTemp3
soilTemp4
leafTemp1
leafTemp2
extraHumid1
extraHumid2
soilMoist1
soilMoist2
soilMoist3
soilMoist4
leafWet1
leafWet2
rxCheckPercent
txBatteryStatus
consBatteryVoltage
hail
hailRate
heatingTemp
heatingVoltage
supplyVoltage
referenceVoltage
windBatteryStatus
rainBatteryStatus
outTempBatteryStatus
inTempBatteryStatus
###

