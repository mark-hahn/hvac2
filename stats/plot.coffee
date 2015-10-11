
log = console.log.bind console
plot = require('plotter').plot
db = require('nano') 'http://localhost:5984/hvac'

# actual usage 8/28 to 9/28    => 1343 kwh
# after solar                  => 1203 kwh
# usage charge for same period => $296.77
# tier 1 $0.15 / kwh (323 kwh)
# tier 2 $0.19 / kwh ( 97 kwh)
# tier 3 $0.26 / kwh (226 kwh) 
# tier 4 $0.31 / kwh (rest)

tiers = [
  [0.05346 + 0.09183, 323]
  [0.09786 + 0.09183,  97]
  [0.14095 + 0.10998, 226]
  [0.19607 + 0.10998, 1e9]
]
chargeByKWH = (kwh) ->
  bondCharge   = kwh * 0.00526
  energyCredit = kwh * 0.00172
  charge = bondCharge - energyCredit
  for rateHrs in tiers
    [rate, hrs] = rateHrs
    hrsInTier = Math.min hrs, kwh
    charge += hrsInTier * rate
    # log {kwh, rate, hrs, hrsInTier, charge: hrsInTier * rate}
    kwh -= hrsInTier
  charge
   
log 'billing check 8/28 to 9/28, 1203 kwhrs, 296.77:', chargeByKWH(1203).toFixed 2

db.view 'all', 'hours', (err, data) ->
    
  ################### SEP ###################
  plotDataTemp = {}
  plotDataPercent = {}
  plotDataNightPercent = {}
  lastDay = null
  allDayMins = nightMins = kwHrs = 0
  days = 0
  
  for row in data.rows
    acMins = +row.value[1] 
    temp   = +row.value[3]
    month  = +row.value[5]
    day    = +row.value[6]
    hour   = +row.value[7]
    if month isnt 9 or not (14 <= day <= 28) then continue
    if temp > 50
      plotDataTemp['' + (day+hour/24).toFixed 3] = temp
    if lastDay and lastDay isnt day
      
      pc = (100*(nightMins/60)/24).toFixed 3
      plotDataNightPercent['' + (lastDay + 0.5)] = pc
      
      pc = (100*(allDayMins/60)/24).toFixed 3
      plotDataPercent['' + (lastDay + 0.5)] = pc
      # plotDataPercent['' + (lastDay+1.00001)] = pc
      kwhrsForDay = (allDayMins / 60) * 3
      kwHrs += kwhrsForDay
      dayCharge = +chargeByKWH kwhrsForDay
      # log {month, day, kwhrs: kwhrsForDay.toFixed(1), temp, dayCharge: dayCharge.toFixed(2) }
      days++
      allDayMins = nightMins = 0
    lastDay = day
    if hour < 9 or hour >= 21
      nightMins += acMins
    allDayMins += acMins
      
  pc = (100*(nightMins/60)/24).toFixed 3
  plotDataNightPercent['' + (lastDay + 0.5)] = pc
      
  pc = (100*(allDayMins/60)/24).toFixed 3
  plotDataPercent['' + (lastDay + 0.5)] = pc
  # plotDataPercent['' + (lastDay+1.00001)] = pc

  plot
    data:      
      maxTemp: plotDataTemp
      percentAC: plotDataPercent
      percentNight: plotDataNightPercent
    filename: 'stats/tempMinsSep.png'

  log '--- sept (estimates based on 9/13 to 9/28) ---'
  log 'AC kwHrs for', days, 'days:', Math.ceil kwHrs
  log 'estimated AC cost for', days, 'days:', chargeByKWH kwHrs
  log 'estimated sept AC bill:', Math.ceil 32 * (chargeByKWH kwHrs) / days
  log 'ALL actual sept bill:', 296.77

  ################### OCT ###################
  plotDataTemp = {}
  plotDataPercent = {}
  plotDataNightPercent = {}
  lastDay = null
  allDayMins = nightMins = kwHrs = 0
  days = 0
  
  for row in data.rows
    acMins = +row.value[1] 
    temp   = +row.value[3]
    month  = +row.value[5]
    day    = +row.value[6]
    hour   = +row.value[7]
    if month isnt 10 then continue
    if temp > 50
      plotDataTemp['' + (day+hour/24).toFixed 3] = temp
    if lastDay and lastDay isnt day
      
      pc = (100*(nightMins/60)/24).toFixed 3
      plotDataNightPercent['' + (lastDay + 0.5)] = pc
      
      pc = (100*(allDayMins/60)/24).toFixed 3
      plotDataPercent['' + (lastDay + 0.5)] = pc
      # plotDataPercent['' + (lastDay+1.00001)] = pc
      kwHrs += (allDayMins / 60) * 3
      days++
      allDayMins = nightMins = 0
    lastDay = day
    if hour < 9 or hour >= 21
      nightMins += acMins
    allDayMins += acMins
      
  pc = (100*(nightMins/60)/24).toFixed 3
  plotDataNightPercent['' + (lastDay + 0.5)] = pc
      
  pc = (100*(allDayMins/60)/24).toFixed 3
  plotDataPercent['' + (lastDay + 0.5)] = pc
  # plotDataPercent['' + (lastDay+1.00001)] = pc

  plot
    data:
      maxTemp: plotDataTemp
      percentAC: plotDataPercent
      percentNight: plotDataNightPercent
    filename: 'stats/tempMinsOct.png'

  log '--- oct ---'
  log 'kwHrs for', days, 'days:', Math.ceil kwHrs
  log 'estimated cost for', days, 'days:', chargeByKWH kwHrs
  log 'estimated oct bill:', Math.ceil 31 * (chargeByKWH kwHrs) / days
