{log, logObj} = require('./log') 'ALEXA'

Alexa = require('alexa-app');
alexaApp = new Alexa.app "echo"

alexaApp.launch (request, response) =>
  response.say "You launched the app!"

alexaApp.intent("number", {
    "slots": { "numberslot": "AMAZON.NUMBER" },
    "utterances": ["say the number {-|numberslot}"]
  }, (request, response) =>
    log request, response
    number = request.slot "numberslot"
    response.say "You asked for the number " + number
  )

exports.alexaReq = (body) =>
  log '\n\n\nbody = \n'
  log body
  log '\n\n\n'
  alexaRes = alexaApp.request JSON.parse body
  log '\n\n\nreturn = \n'
  log alexaRes
  log '\n\n\n'
