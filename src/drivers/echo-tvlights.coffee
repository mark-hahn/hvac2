{log, logObj} = require('./log') 'LIGHTS'

request = require 'request'

exports.alexaReq = (alexaApp) =>
  bulbs = {
     all           : 'tvall',
    'front left'   : 'frontLeft',
    'front middle' : 'frontMiddle',
    'front right'  : 'frontRight',
    'back left'    : 'backLeft',
    'back middle'  : 'backMiddle',
    'back right'   : 'backRight'
  }

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
      # log bulbs, req.slot('light'), {bulb,level}
      url = "http://hahnca.com/lights/ajax?json=" +
              JSON.stringify {bulb, cmd:'moveTo', val:{level}}
      # log url
      request url, (error, res2, body) =>
        if error || res2.statusCode != 200
          log "intent tv_light error", res2.statusCode, error
          res.say "error " + res2.statusCode
          return;
      res.say "ok"

  modeBulbs = [
    'frontLeft',
    'frontMiddle',
    'frontRight',
    'backLeft',
    'backMiddle',
    'backRight'
  ]
  modeLevels = {
    linda: [0,0,0,255,0,255]
    mark:  [255,0,255,0,0,255]
  }

  alexaApp.intent "tv_light_mode_linda",
      utterances : ["mode linda"]
    , (req, res) =>
        for i in [0..6]
          bulb = modeBulbs[i]
          level = modeLevels.linda[i]
          url = "http://hahnca.com/lights/ajax?json=" +
                     JSON.stringify({bulb:bulb, cmd:'moveTo', val:{level}});
          # log url
          request url, (error, res2, body) =>
            if (error || res2.statusCode != 200)
              log "intent tv_light_mode_linda error", res2.statusCode, error
              res.say "error " + res2.statusCode
              return
        res.say("ok");

  alexaApp.intent "tv_light_mode_mark",
      utterances : ["mode mark"]
    , (req, res) =>
        for i in [0..6]
          bulb = modeBulbs[i]
          level = modeLevels.mark[i]
          url = "http://hahnca.com/lights/ajax?json=" +
                     JSON.stringify({bulb:bulb, cmd:'moveTo', val:{level}});
          # log url
          request url, (error, res2, body) =>
            if (error || res2.statusCode != 200)
              log "intent tv_light_mode_mark error", res2.statusCode, error
              res.say "error " + res2.statusCode
              return
        res.say("ok");
