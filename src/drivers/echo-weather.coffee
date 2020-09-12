{log, logObj} = require('./log') 'WEATH'

sqlite3 = require "better-sqlite3"

try
  db = new sqlite3 '/var/lib/weewx/weewx.sdb', {readonly:yes, fileMustExist:yes}
catch e
  log 'Error opening weewx db', e.message
  return

dayNames = [
  'sunday'
  'monday'
  'tuesday'
  'wednesday'
  'thursday'
  'friday'
  'saturday'
]

getStats = =>
  stats = {}
  try
    row = db.prepare('SELECT dateTime, outTemp, outHumidity, ' +
                        'windSpeed, windDir, windGust, windGustDir ' +
                    'FROM archive ORDER BY dateTime DESC LIMIT 1')
            .get()
    all = db.prepare 'SELECT dateTime, rain FROM archive WHERE dateTime > ' +
                      Math.round(Date.now()/1000 - 6 * 24 * 60 * 60)
            .all()
    row.rainNum = 0
    row.firstRain = null
    for timeRain in all
      row.rainNum += timeRain.rain
      if timeRain.rain > 0 and row.firstRain == null
        row.firstRain = new Date timeRain.dateTime * 1000
    row.rain = row.rainNum.toFixed 2
    row.firstRain = dayNames[row.firstRain.getDay()]
  catch e
    log 'Error reading weewx db', e.message
    db.close()
    return
  return row

exports.alexaReq = (alexaApp, getAppName) =>

  alexaApp.intent "home_weather_all",
    utterances: ['all']
  , (req, res) =>
    row = getStats()
    log row
    rainMsg = if row.rainNum == 0.0
      "and there has been no rain"
    else
      "and there has been #{row.rain} inches of rain since #{row.firstRain}"

    res.say "the temperature is #{row.outTemp} degrees, " +
            "the humidity is #{row.outHumidity} percent, "   +
            "the wind is gusting at #{row.windGust} miles per hour, " + rainMsg

  alexaApp.intent "home_weather_temp",
    utterances: ['temp']
  , (req, res) =>
    row = getStats()
    res.say "the temp is #{row.outTemp} degrees"
