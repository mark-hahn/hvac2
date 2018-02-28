{log, logObj} = require('./log') 'ECHO'

Alexa = require('alexa-app');
alexaApp = new Alexa.app "echo"

appNames = {
  "amzn1.ask.skill.1e6c5946-4476-453a-964b-8c561a0a80a8": "home-weather",
  "amzn1.ask.skill.bb9eb551-6df6-482c-9e53-a099f3a747bb": "tv-lights",
  "amzn1.ask.skill.2b91b0b8-fa93-476c-a369-e43c54e54e09": "tv-room"
}
getAppName = (request) =>
  return appNames[request.sessionDetails.application.applicationId];

require('./echo-tvlights').alexaReq(alexaApp, getAppName);
require('./echo-rooms')   .alexaReq(alexaApp, getAppName);
require('./echo-weather') .alexaReq(alexaApp, getAppName);

alexaApp.launch (request, response) =>
  response.say "launched #{getAppName request}"

exports.alexaReq = (body, res) =>
  alexaApp
    .request JSON.parse body
    .then (result) =>
      # log {result}
      res.writeHead 200, "Content-Type": "text/json"
      res.end JSON.stringify result
    .error  (err) =>
      res.status(500)
         .send(err.message);
