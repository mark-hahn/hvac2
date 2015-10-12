
log     = console.log.bind console
fs      = require 'fs'
plot    = require('plotter').plot
gnuPlot = require 'gnuplot'
db      = require('nano') 'http://hahnca.com:5984/hvac'

# socal edison
# actual usage 8/28 to 9/28    => 1343 kwh
# after solar                  => 1203 kwh
# usage charge for same period => $296.77
# tier 1 $0.15 / kwh (323 kwh)
# tier 2 $0.19 / kwh ( 97 kwh)
# tier 3 $0.26 / kwh (226 kwh) 
# tier 4 $0.31 / kwh (rest)

# power meter readings (AC on/off)
# day:   2.83 - 0.04  => 2.79
# night: 4.11 - 1.56  => 2.55
# night: 4.22 - 1.74  => 2.48
ACPwrUsage = 2.6

# socal edison pricing
tiers = [
  [0.05346 + 0.09183, 323]
  [0.09786 + 0.09183,  97]
  [0.14095 + 0.10998, 226]
  [0.19607 + 0.10998, 1e9]
]
chargeByKWH = (kwh, topTier) ->
  if topTier then return tiers[3][0] * kwh
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
   
log 'aug est, 900 kwh', chargeByKWH(900)
log 'billing check 8/28 to 9/28, 1203 kwhrs, 296.77:', chargeByKWH(1203).toFixed 2
sepBillWithSolar = chargeByKWH 1343
log 'bill if solar included', sepBillWithSolar.toFixed 2

minsPc = (mins) -> (100 * mins / (24*60)).toFixed 2

db.view 'all', 'hours', (err, data) ->
    
  ################### SEP ###################
  gnuPlotDataTemp      = ["unixtime MaxTemp"]
  gnuPlotDataUsage     = ["unixtime AllDayUsage NightUsage"]
  lastDay              = null
  days = allDayMins = nightMins = kwHrs = dayHighTemp = 0
  
  
  for row in data.rows
    acMins = +row.value[1] 
    temp   = +row.value[3]
    month  = +row.value[5]
    day    = +row.value[6]
    hour   = +row.value[7]
    timeMS = Math.round Date.parse '2015-' + row.value[5] + '-' + row.value[6] + 'T' + 
                                             row.value[7] + ':00:00'
    unixtime = Math.round timeMS / 1000
    # gnuPlotDataUsage.push "#{unixtime} #{0} #{0}"
    
    if month isnt 9 or not (14 <= day <= 28) then continue
    if temp > 50
      plotDataTemp['' + (day+hour/24).toFixed 3] = temp
    if lastDay and lastDay isnt day
      kwhrsForDay = (allDayMins / 60) * ACPwrUsage
      kwHrs += kwhrsForDay
      dayCharge = +chargeByKWH(kwhrsForDay, yes)
      # log {month, day, kwhrs: kwhrsForDay.toFixed(1), dayHighTemp, dayCharge: dayCharge.toFixed(2) }
      # log {day:lastDay, kwhrs: kwhrsForDay.toFixed(0), temp: dayHighTemp, cost: dayCharge.toFixed(0) }
      gnuPlotDataUsage.push "#{unixtime} #{minsPc allDayMins} #{minsPc nightMins}"
      days++
      dayHighTemp = allDayMins = nightMins = 0
    lastDay = day
    if hour < 9 or hour >= 21
      nightMins += acMins
    allDayMins += acMins
    dayHighTemp = Math.max dayHighTemp, temp

    gnuPlotDataTemp.push "#{unixtime} #{temp}"
    
  # gnuPlotDataUsage.push "#{unixtime} #{minsPc allDayMins} #{minsPc nightMins}"
      
  kwhrsForDay = (allDayMins / 60) * ACPwrUsage
  kwHrs += kwhrsForDay
  dayCharge = +chargeByKWH kwhrsForDay, yes
  # log {month, day, kwhrs: kwhrsForDay.toFixed(1), dayHighTemp, dayCharge: dayCharge.toFixed(2) }
  log {day:lastDay, kwhrs: kwhrsForDay.toFixed(0), temp: dayHighTemp, cost: dayCharge.toFixed(0) }

  fs.writeFileSync 'stats/gnuPlotDataUsage.txt', gnuPlotDataUsage.join '\n'
  fs.writeFileSync 'stats/gnuPlotDataTemp.txt',  gnuPlotDataTemp.join  '\n'
  
  gnuPlot()
    # .print 'samples(x) = $0 > 4 ? 5 : ($0+1);'
    # .print 'back1 = back2 = back3 = back4 = back5 = sum = 0;'
    # .print 'avg5(x) = (shift5(x), (back1+back2+back3+back4+back5)/samples($0));'
    # .print 'shift5(x) = (back5 = back4, back4 = back3, back3 = back2, back2 = back1, back1 = x);'
    .set 'term svg dynamic'
    .set 'title "HVAC temp and AC usage mins 9-14 to 9-28"'
    .set 'key autotitle columnhead'
    .set 'timefmt "%s"'
    .set 'xdata time'
    .set 'output "/root/Downloads/hvac-sep.svg"'
    .set 'format x "%d"'
    .plot '"stats/gnuPlotDataTemp.txt"  using 1:2 with lines,
           "stats/gnuPlotDataUsage.txt" using 1:2 with fsteps,
           "stats/gnuPlotDataUsage.txt" using 1:3 with fsteps'
    .end()
          #  "stats/gnuPlotDataUsage.txt" using 1:(avg5($5)) with fsteps'
      
  log ''
  log '--- sept (AC estimates based on 9/14 to 9/28) ---'
  log 'AC kwHrs for', days, 'days:', Math.ceil kwHrs
  log 'est. AC cost for', days, 'days:', chargeByKWH(kwHrs, yes).toFixed 2
  estACMonthKwh = (32/days) * kwHrs
  estACBill = chargeByKWH estACMonthKwh, yes
  log 'est. sept AC bill:',  estACBill.toFixed 2
  log ''
  log '--- sept (ALL pwr estimates based on 9/14 to 9/28) ---'
  otherKWHrs = 1343 - estACMonthKwh
  otherKWHrsPerDay = otherKWHrs / days
  estOtherBill = chargeByKWH 32 * otherKWHrsPerDay
  log 'est. sept other bill:', estOtherBill.toFixed 2
  log 'est. sept ALL bill:',  (estACBill + estOtherBill).toFixed 2
  log 'ALL actual sept 2015 bill (w solar):', sepBillWithSolar.toFixed 2


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
      kwHrs += (allDayMins / 60) * ACPwrUsage
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

  log ''
  log '--- oct ---'
  log 'AC kwHrs for', days, 'days:', Math.ceil kwHrs
  estACMonthKwhrs = 31 * (kwHrs / days)
  log 'est. AC cost for', days, 'days:', chargeByKWH(kwHrs, yes).toFixed 2
  log 'est. AC cost for month', chargeByKWH(estACMonthKwhrs, yes).toFixed 2
  log 'est. other month bill', chargeByKWH(31 * otherKWHrsPerDay).toFixed 2
  estAllMonthKwhrs = estACMonthKwhrs + otherKWHrsPerDay * 31
  log 'est. ALL month bill:', chargeByKWH(estAllMonthKwhrs).toFixed 2
  log ''
