{log, logObj} = require('./log') 'ROOMS'

request = require 'request'

exports.alexaReq = (alexaApp) =>
  alexaApp.intent "tv_room_mode",
      utterances: ['set mode {mode}', '{mode}'],
      slots: { mode: "mode" }
    , (req, res) =>
      # bulb  = bulbs[req.slot 'light']
      # level = switch req.slot 'level'
      #   when 'off' then 0
      #   when 'dim' then 32
      #   when 'on'  then 255
      # # log bulbs, req.slot('light'), {bulb,level}
      # url = "http://hahnca.com/lights/ajax?json=" +
      #         JSON.stringify {bulb, cmd:'moveTo', val:{level}}
      # # log url
      # request url, (error, res2, body) =>
      #   if error || res2.statusCode != 200
      #     log "intent tv_light error", res2.statusCode, error
      #     res.say "error " + res2.statusCode
      #     return;
      res.say "tv room mode "+ req.slot 'mode'
