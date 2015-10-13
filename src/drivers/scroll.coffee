###
  src/drivers/scroll.coffee
###

{log, logObj} = require('./utils') 'SCROL'
$ = require('imprea')()

hyst = 0.25

rooms        = ['tvRoom', 'kitchen', 'master', 'guest']
lastTemp     = {tvRoom:null, kitchen:null, master:null, guest:null}
lastSetpoint = {tvRoom:null, kitchen:null, master:null, guest:null}
lastActive   = {tvRoom:no,   kitchen:no,   master:no,   guest:no}
setpoint     = {}
active       = {}
gnuPlotDataTemp    = {tvRoom:[], kitchen:[], master:[], guest:[]}
gnuPlotDataSetLow  = []
gnuPlotDataSetHigh = []
gnuPlotDataActive  = []

$.react 'temp_tvRoom', 'temp_kitchen', 'temp_master', 'temp_guest',
        'ws_tstat_data', 'timing_hvac', 'timing_dampers', (name) ->
  unixTime = Math.round Date.now() / 1000
  temp = {tvRoom:@temp_tvRoom, kitchen:@temp_kitchen, \
          master:@temp_master, guest:@temp_guest}
  {room, setpoint} = @ws_tstat_data
  setpoint[room] = setpoint
  for room in rooms
    active[room] = (@timing_dampers[room] and 
                   (@timing_hvac[heat] or @timing_hvac[cool]))
                   
    if temp[room] isnt lastTemp [room]
      gnuPlotDataTemp[room].push "#{unixTime} #{temp[room]}"
      lastTemp [room] = temp[room]
    
    if setpoint[room] isnt lastSetpoint [room]
      gnuPlotDataSetLow[room] .push "#{unixTime} #{setpoint[room]-hyst}"
      gnuPlotDataSetHigh[room].push "#{unixTime} #{setpoint[room]+hyst}"
      lastSetpoint [room] = setpoint[room]
    
    
    
  
  
