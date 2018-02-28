{log, logObj} = require('./log') 'WEATHER'

sqlite3 = require "better-sqlite3"

try
  db = new sqlite3 '/var/lib/weewx/weewx.sdb', {readonly:yes, fileMustExist:yes}
catch e
  log 'Error opening weewx db', e.message
  return

getStats = =>
  stats = {}
  try
    row = db.prepare('SELECT dateTime, outTemp, outHumidity, ' +
                        'windSpeed, windDir, windGust, windGustDir ' +
                    'FROM archive ORDER BY dateTime DESC LIMIT 1')
            .get()
  catch e
    log 'Error reading weewx db', e.message
    db.close()
    return
  return row



exports.alexaReq = (alexaApp) =>
  alexaApp.intent "home_weather_all",
    utterances: ['all']
  , (req, res) =>
    row = getStats()
    res.say "the roof temperature is #{row.outTemp} degrees, " +
            "the humidity is #{row.outHumidity} percent, "   +
            "and the wind is gusting at #{row.windGust} miles per hour"
