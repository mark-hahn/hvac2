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
weewx_data      
  outTemp:      84.5
  outHumidity:  32
  rainRate:     0
  windSpeed:    1
  windDir:      260
  windGust:     4
  windGustDir:  225

    dateTime: 1446334020,
    usUnits: 1,
    interval: 1,
    barometer: 29.965,
    pressure: 29.87210327146843,
    altimeter: 29.954077428388796,
    inTemp: 74.9,
    outTemp: 84.3,
    inHumidity: 48,
    outHumidity: 31,
    windSpeed: 3,
    windDir: 260,
    windGust: 6,
    windGustDir: 225,
    rainRate: 0,
    rain: 0,
    dewpoint: 50.3415556529237,
    windchill: 84.3,
    heatindex: 84.3,
    ET: 0,
    radiation: null,
    UV: null,
    extraTemp1: null,
    extraTemp2: null,
    extraTemp3: null,
    soilTemp1: -26,
    soilTemp2: -90,
    soilTemp3: -26,
    soilTemp4: -90,
    leafTemp1: -86,
    leafTemp2: -90,
    extraHumid1: null,
    extraHumid2: null,
    soilMoist1: 128,
    soilMoist2: 8,
    soilMoist3: 32,
    soilMoist4: 32,
    leafWet1: 4,
    leafWet2: 8,
    rxCheckPercent: 98.22916666666667,
    txBatteryStatus: 0,
    consBatteryVoltage: 4.67,
    hail: null,
    hailRate: null,
    heatingTemp: null,
    heatingVoltage: null,
    supplyVoltage: null,
    referenceVoltage: null,
    windBatteryStatus: null,
    rainBatteryStatus: null,
    outTempBatteryStatus: null,
    inTempBatteryStatus: null }
    10-31 16:27:36 wxsta  weewx data { dateTime: 1446334020,
    usUnits: 1,
    interval: 1,
    barometer: 29.965,
    pressure: 29.87210327146843,
    altimeter: 29.954077428388796,
    inTemp: 74.9,
    outTemp: 84.3,
    inHumidity: 48,
    outHumidity: 31,
    windSpeed: 3,
    windDir: 260,
    windGust: 6,
    windGustDir: 225,
    rainRate: 0,
    rain: 0,
    dewpoint: 50.3415556529237,
    windchill: 84.3,
    heatindex: 84.3,
    ET: 0,
    radiation: null,
    UV: null,
    extraTemp1: null,
    extraTemp2: null,
    extraTemp3: null,
    soilTemp1: -26,
    soilTemp2: -90,
    soilTemp3: -26,
    soilTemp4: -90,
    leafTemp1: -86,
    leafTemp2: -90,
    extraHumid1: null,
    extraHumid2: null,
    soilMoist1: 128,
    soilMoist2: 8,
    soilMoist3: 32,
    soilMoist4: 32,
    leafWet1: 4,
    leafWet2: 8,
    rxCheckPercent: 98.22916666666667,
    txBatteryStatus: 0,
    consBatteryVoltage: 4.67,
    hail: null,
    hailRate: null,
    heatingTemp: null,
    heatingVoltage: null,
    supplyVoltage: null,
    referenceVoltage: null,
    windBatteryStatus: null,
    rainBatteryStatus: null,
    outTempBatteryStatus: null,
    inTempBatteryStatus: null }
    10-31 16:27:40 wxsta  weewx data { dateTime: 1446334020,
    usUnits: 1,
    interval: 1,
    barometer: 29.965,
    pressure: 29.87210327146843,
    altimeter: 29.954077428388796,
    inTemp: 74.9,
    outTemp: 84.3,
    inHumidity: 48,
    outHumidity: 31,
    windSpeed: 3,
    windDir: 260,
    windGust: 6,
    windGustDir: 225,
    rainRate: 0,
    rain: 0,
    dewpoint: 50.3415556529237,
    windchill: 84.3,
    heatindex: 84.3,
    ET: 0,
    radiation: null,
    UV: null,
    extraTemp1: null,
    extraTemp2: null,
    extraTemp3: null,
    soilTemp1: -26,
    soilTemp2: -90,
    soilTemp3: -26,
    soilTemp4: -90,
    leafTemp1: -86,
    leafTemp2: -90,
    extraHumid1: null,
    extraHumid2: null,
    soilMoist1: 128,
    soilMoist2: 8,
    soilMoist3: 32,
    soilMoist4: 32,
    leafWet1: 4,
    leafWet2: 8,
    rxCheckPercent: 98.22916666666667,
    txBatteryStatus: 0,
    consBatteryVoltage: 4.67,
    hail: null,
    hailRate: null,
    heatingTemp: null,
    heatingVoltage: null,
    supplyVoltage: null,
    referenceVoltage: null,
    windBatteryStatus: null,
    rainBatteryStatus: null,
    outTempBatteryStatus: null,
    inTempBatteryStatus: null
###