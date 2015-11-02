
log     = console.log.bind console
fs      = require 'fs'
plot    = require('plotter').plot
gnuPlot = require 'gnuplot'
db      = require('nano') 'http://localhost:5984/hvac'

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
# ACPwrUsage = 2.6

# socal edison pricing
# tiers = [
#   [0.05346 + 0.09183, 323]
#   [0.09786 + 0.09183,  97]
#   [0.14095 + 0.10998, 226]
#   [0.19607 + 0.10998, 1e9]
# ]
# chargeByKWH = (kwh, topTier) ->
#   if topTier then return tiers[3][0] * kwh
#   bondCharge   = kwh * 0.00526
#   energyCredit = kwh * 0.00172
#   charge = bondCharge - energyCredit
#   for rateHrs in tiers
#     [rate, hrs] = rateHrs
#     hrsInTier = Math.min hrs, kwh
#     charge += hrsInTier * rate
#     # log {kwh, rate, hrs, hrsInTier, charge: hrsInTier * rate}
#     kwh -= hrsInTier
#   charge
   
# log 'billing check 8/28 to 9/28, 1203 kwhrs, 296.77:', chargeByKWH(1203).toFixed 2
# sepBillWithSolar = chargeByKWH 1343
# log 'bill if solar included', sepBillWithSolar.toFixed 2

minsPc = (mins) -> (100 * mins / (24*60)).toFixed 2

plotPeriod = (label, plotMonth, cb) ->
  title    = 'title "HVAC Temp and AC usage: ' + label + '"'
  titleId  = label.replace /\s+/g, '_'
  filePath = '/root/dev/apps/hvac2/stats/hvac_' + titleId + '.svg'
  log 'plot: processing file', filePath
  
  ###
    function(doc) {
      if(doc.type == 'hour') emit(doc._id, doc);
    }
  ###
  db.view 'all', 'hours', (err, data) ->
    if err
      log 'plot err reading db view "hours"', err
      process.exit 1
      return
      
    gnuPlotDataTemp    = ["unixtime Temp"]
    gnuPlotDataUsage   = ["unixtime AllDayUsage NightUsage"]
    lastDay = lastTime = unixtime = null
    days = allDayMins  = nightMins = kwHrs = dayHighTemp = 0
    firstDay = yes

    for row in data.rows
      {_id, acSecs, avgExtTemp, maxExtTemp, minExtTemp, 
        year, month, day, hour} = row.value
      acMins = Math.round Math.ceil +acSecs/60
      if maxExtTemp is    0 then maxExtTemp = avgExtTemp
      if minExtTemp is 1000 then minExtTemp = avgExtTemp
      temp   = (if 9 <= +hour < 21 then +maxExtTemp else +minExtTemp)
      
      if _id in [ 'hour:15-10-09-13'
                  'hour:15-10-09-14'
                  'hour:15-10-10-13' ]
        # log 'excluded doc:', row.value
        continue
      
      timeMS = Math.round new Date(+year, +month-1, +day, +hour).getTime() +
               -18.75 * 60 * 60 * 1e3  # don't know why this is needed
      unixtime = Math.round timeMS / 1000
      
      dayBreak = ->
        # log 'breaking day', lastDay, _id
        # kwhrsForDay = (allDayMins / 60) * ACPwrUsage
        # kwHrs += kwhrsForDay
        # dayCharge = +chargeByKWH(kwhrsForDay, yes)
        # log {month, day, kwhrs: kwhrsForDay.toFixed(1), dayHighTemp, dayCharge: dayCharge.toFixed(2) }
        # log {day:lastDay, kwhrs: kwhrsForDay.toFixed(0), temp: dayHighTemp, cost: dayCharge.toFixed(0) }

        if firstDay
          gnuPlotDataUsage.push \
              "#{unixtime} #{minsPc allDayMins} #{minsPc nightMins}"
          firstDay = no
        else
          gnuPlotDataUsage.push \
              "#{lastTime} #{minsPc allDayMins} #{minsPc nightMins}"
        
        days++
        lastTime = unixtime
        dayHighTemp = allDayMins = nightMins = 0
        # log 'day:', days,  _id
      
      if _id[5..9] isnt plotMonth then continue
      
      # log 'hour', {_id, label, temp, acMins}
      
      if lastDay and lastDay isnt day then dayBreak()
      
      lastDay = day
      
      if hour < 9 or hour >= 21
        nightMins += acMins
      allDayMins += acMins
      
      if temp
        dayHighTemp = Math.max dayHighTemp, temp
        gnuPlotDataTemp.push "#{unixtime} #{temp}"
        
    dayBreak()

    # log 'end', {_id, label, temp, allDayMins, nightMins,\
    #             lastTime: new Date(lastTime*1e3), unixtime: new Date(unixtime*1e3)}
    
    if lastTime
      gnuPlotDataUsage.push "#{lastTime} #{minsPc allDayMins} #{minsPc nightMins}"
    gnuPlotDataUsage.push "#{unixtime} #{minsPc allDayMins} #{minsPc nightMins}"
    
    # kwhrsForDay = (allDayMins / 60) * ACPwrUsage
    # kwHrs += kwhrsForDay
    # dayCharge = +chargeByKWH kwhrsForDay, yes
    # log {month, day, kwhrs: kwhrsForDay.toFixed(1), dayHighTemp, dayCharge: dayCharge.toFixed(2) }
    # log {day:lastDay, kwhrs: kwhrsForDay.toFixed(0), temp: dayHighTemp, cost: dayCharge.toFixed(0) }

    tempPath  = "/tmp/temp-#{titleId}.txt"
    usagePath = "/tmp/usage-#{titleId}.txt"
    
    fs.writeFileSync tempPath,  gnuPlotDataTemp .join '\n'
    fs.writeFileSync usagePath, gnuPlotDataUsage.join '\n'
    
    if days
      gnuPlot()
        .set 'term svg dynamic'
        .set title
        .set 'grid'
        .set 'key off' # autotitle columnhead'
        .set 'label "`date "+%m/%d %H:%M"`" right at graph 1,1.07 font "arial,10"'
        .set 'timefmt "%s"'
        .set 'xdata time'
        .set 'output "' + filePath + '"'
        .set 'format x "%d"'
        .plot "\"#{tempPath}\"  using 1:2 with lines,
               \"#{usagePath}\" using 1:3 with steps,
               \"#{usagePath}\" using 1:2 with steps"
        .end cb
      return
    cb()
        
    # log ''
    # log '--- sept (AC estimates based on 9/14 to 9/28) ---'
    # log 'AC kwHrs for', days, 'days:', Math.ceil kwHrs
    # log 'est. AC cost for', days, 'days:', chargeByKWH(kwHrs, yes).toFixed 2
    # estACMonthKwh = (32/days) * kwHrs
    # estACBill = chargeByKWH estACMonthKwh, yes
    # log 'est. sept AC bill:',  estACBill.toFixed 2
    # log ''
    # log '--- sept (ALL pwr estimates based on 9/14 to 9/28) ---'
    # otherKWHrs = 1343 - estACMonthKwh
    # otherKWHrsPerDay = otherKWHrs / days
    # estOtherBill = chargeByKWH 32 * otherKWHrsPerDay
    # log 'est. sept other bill:', estOtherBill.toFixed 2
    # log 'est. sept ALL bill:',  (estACBill + estOtherBill).toFixed 2
    # log 'ALL actual sept 2015 bill (w solar):', sepBillWithSolar.toFixed 2

# plotPeriod 'October 2015', '15-10', ->
plotPeriod 'November 2015', '15-11', ->
  log 'plot finished', new Date().toString()[0..23]

