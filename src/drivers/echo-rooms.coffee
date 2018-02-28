{log, logObj} = require('./log') 'ROOMS'

request = require 'request'

exports.alexaReq = (alexaApp) =>
  alexaApp.intent "tv_room_mode",
      utterances: ['set mode {mode}', '{mode}'],
      slots: { mode: "mode" }
    , (req, res) =>
      {modes, fans, temps, setpoints} = getRooms()
      log {modes, fans, temps, setpoints}

      # url = "http://hahnca.com/lights/ajax?json=" +

      # # log url
      # request url, (error, res2, body) =>
      #   if error || res2.statusCode != 200
      #     log "intent tv_light error", res2.statusCode, error
      #     res.say "error " + res2.statusCode
      #     return;
      res.say "tv room mode "+ req.slot 'mode'
