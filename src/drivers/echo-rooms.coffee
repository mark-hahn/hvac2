{log, logObj} = require('./log') 'ROOMS'

request = require 'request'

exports.alexaReq = (alexaApp) =>
  alexaApp.intent "tv_room_mode",
      utterances: ['set mode {mode}', '{mode}'],
      slots: { mode: "mode" }
    , (req, res) =>
      # res.say 'hello'

      url = "http://hahnca.com/hvac/roomStats"
      request url, (error, res2, body) =>
        if error || res2.statusCode != 200
          log "intent tv_light error", res2.statusCode, error
          res.say "error " + res2.statusCode
          return;
        rooms = JSON.parse body
        log res, rooms
        res.say "the temp setting in tv room is #{rooms.tvRoom?.setpoint ? 'not available'}"

###
{
kitchen: {
type: "tstat",
room: "kitchen",
fan: false,
mode: "off",
qc: false,
setpoint: 70
},
master: {
type: "tstat",
room: "master",
fan: false,
mode: "heat",
qc: false,
setpoint: 65
},
guest: {
type: "tstat",
room: "guest",
fan: false,
mode: "off",
qc: false,
setpoint: 70
},
tvRoom: {
type: "tstat",
room: "tvRoom",
fan: false,
mode: "heat",
qc: false,
setpoint: 72.5
}
}
###
