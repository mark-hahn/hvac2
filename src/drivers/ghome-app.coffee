
{log, logObj} = require('./log') 'JOVO'

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

{App} = require 'jovo-framework'

config = logging: true, requestLogging: no, responseLogging: no

app = new App config

app.setHandler
    'LAUNCH': () ->
      @toIntent('HelloWorldIntent');

    'HelloWorldIntent': () ->
      @ask 'Hello World mark!'

    'weatherIntent': () ->
      row = getStats()
      log row
      rainMsg = if row.rainNum == 0.0
        "and there has been no rain"
      else
        "and there has been #{row.rain} inches of rain since #{row.firstRain}"

      @ask "the temperature is #{row.outTemp} degrees, " +
              "the humidity is #{row.outHumidity} percent, "   +
              "the wind is gusting at #{row.windGust} miles per hour, " + rainMsg

module.exports.app = app;
