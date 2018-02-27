{log, logObj} = require('./log') 'ALEXA'
request = require 'request'

Alexa = require('alexa-app');
alexaApp = new Alexa.app "echo"

bulbs =
  'front left'   : 'frontLeft'
  'front middle' : 'frontMiddle'
  'front right'  : 'frontRight'
  'back left'    : 'backLeft'
  'back middle'  : 'backMiddle'
  'back right'   : 'backRight'

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

alexaApp.intent "tv_lights_all_on",
    "utterances": ["all on"]
  , (req, res) =>
    url = "http://hahnca.com/lights/ajax?json=" +
               JSON.stringify {bulb:'tvall', cmd:'moveTo', val:{level:255}}
    log url
    request url, (error, res2, body) =>
      if error || res2.statusCode != 200
        log "intent tv_lights_all_on error", res2.statusCode, error
        res.say "error " + res2.statusCode
        return;
    res.say "ok"

alexaApp.intent "tv_lights_all_dim",
    "utterances": ["all dim"]
  , (req, res) =>
    url = "http://hahnca.com/lights/ajax?json=" +
               JSON.stringify {bulb:'tvall', cmd:'moveTo', val:{level:32}}
    log url
    request url, (error, res2, body) =>
      if error || res2.statusCode != 200
        log "intent tv_lights_all_dim error", res2.statusCode, error
        res.say "error " + res2.statusCode
        return;
    res.say "ok"

alexaApp.intent "tv_lights_all_off",
    "utterances": ["all off"]
  , (req, res) =>
    url = "http://hahnca.com/lights/ajax?json=" +
               JSON.stringify {bulb:'tvall', cmd:'moveTo', val:{level:0}}
    log url
    request url, (error, res2, body) =>
      if error || res2.statusCode != 200
        log "intent tv_lights_all_off error", res2.statusCode, error
        res.say "error " + res2.statusCode
        return;
    res.say "ok"

alexaApp.intent "tv_light",
    utterances: [
      "set {light} to {level}"
      "set {light} {level}"
      "{light} {level}"
    ],
    slots: { light: "which_tv_light", level: "level" },
  , (req, res) =>
    bulb  = bulbs[req.slot 'light']
    level = switch req.slot 'level'
      when 'off' then 0
      when 'dim' then 32
      when 'on'  then 255
    log {bulb,level}
    url = "http://hahnca.com/lights/ajax?json=" +
            JSON.stringify {bulb, cmd:'moveTo', val:{level}}
    log url
    request url, (error, res2, body) =>
      if error || res2.statusCode != 200
        log "intent tv_light error", res2.statusCode, error
        res.say "error " + res2.statusCode
        return;
    res.say "ok"

exports.alexaReq = (body, res) =>
  alexaApp
    .request JSON.parse body
    .then (result) =>
      log {result}
      res.writeHead 200, "Content-Type": "text/json"
      res.end JSON.stringify result
    .error  (err) =>
      res.status(500)
         .send(err.message);
