{log, logObj} = require('./log') 'ECHO'

Alexa = require('alexa-app');
alexaApp = new Alexa.app "echo"
(require './echo-tvlights') alexaApp

alexaApp.launch (request, response) =>
  response.say "You launched the app!"

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
