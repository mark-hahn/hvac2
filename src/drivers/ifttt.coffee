
{log, logObj} = require('./log') 'IFTT'
ws = require './websock-server'
http = require 'http'
urlParse = require('url').parse

rooms = ['tvRoom', 'kitchen', 'master', 'guest']
roomAliases =
  all:                   'all'

  TV:                    'tvRoom'
  'the TV':              'tvRoom'
  'TV room':             'tvRoom'
  'the TV room':         'tvRoom'

  living:                'tvRoom'
  'the living':          'tvRoom'
  'living room':         'tvRoom'
  'the living room':     'tvRoom'

  sewing:                'kitchen'
  'the sewing':          'tvRoom'
  'sewing room':         'kitchen'
  'the sewing room':     'kitchen'
    
  kids:                  'kitchen'
  'the kids':            'tvRoom'
  'kids room':           'kitchen'
  'the kids room':       'kitchen'

  master:                'master'
  'the master':          'master'
  'master room':         'master'
  'the master room':     'master'

  guest:                 'guest'
  'the guest':           'guest'
  'guest room':          'guest'
  'the guest room':      'guest'

hostname = '127.0.0.1';
port = 1340

server = http.createServer( (req, res) ->
  {url} = req
  res.statusCode = 200
  res.setHeader 'Content-Type', 'text/plain'
  log 'req:', url
  {cmd, room, num} = urlParse(url, true).query

  if room
    room = roomAliases[room]
    if not room 
      log('bad room');
      res.statusCode = 401;
      res.end()
      return

  if num
    num = Number(num)
    if typeof num != 'number'
      log('bad number');
      res.statusCode = 401;
      res.end()
      return

  switch cmd
    when 'off' 
      if room is 'all'
        for room in rooms then ws.setStat room, {mode:'off', fan:off}
      else if room        then ws.setStat room, {mode:'off', fan:off}
    when 'heat'    then  if room          then ws.setStat room, {mode:'heat'}
    when 'ac'      then  if room          then ws.setStat room, {mode:'cool'}
    when 'up'      then  if room          then ws.setStatTicks room,  0.5
    when 'down'    then  if room          then ws.setStatTicks room, -0.5
    when 'set'     then  if room and num  then ws.setStat room, {setpoint: num}
    else
      log('bad request');
      res.statusCode = 404;

  res.end()
);

server.listen(port, hostname, () =>
  log("Server running on port #{port}");
);

###
* all_off:   turn all rooms off
* off:       turn room $ off
* ac:        turn room $ ac on
* heat:      turn room $ heat on
up:        turn room $ up # ticks
down:      turn room $ down # ticks
* set:        set room $ to #
###
