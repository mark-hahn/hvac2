
log  = console.log.bind console
plot = require 'gnuplot'
db   = require('nano') 'http://localhost:5984/hvac'

# plot() 
#     .set 'term svg fname "Helvetica" fsize 14\n'
#     .set 'output "/root/Downloads/test2.svg"'
#     .set 'title "Some Math Functions"'
#     .set 'xrange [-10:10]'
#     .set 'yrange [-2:2]'
#     .set 'zeroaxis'
#     .plot 'sin(x)'
#     .end() 
#     
    # plot f1(x) with lines lt 1 dt solid, f2(x) with lines lt 1 dt 3

# 9/8 to 9/28 $895

### hours
 doc ->
  if doc.type is 'hour'
    emit doc._id, [
      doc.samples              #0
      Math.ceil doc.acSecs/60  #1
      doc.avgExtTemp           #2
      doc.maxExtTemp           #3
      doc.minExtTemp           #4
      doc.month                #5
      doc.day                  #6
      doc.hour                 #7
    ]

db.view 'all', 'hours',  err, data ->
  
  plotDataTemp = {}
  plotDataPercent = {}
  lastDay = null
  dayMins = kwHrs = 0
  
  for row in data.rows
    acMins = +row.value[1] 
    temp   = +row.value[3]
    month  = +row.value[5]
    day    = +row.value[6]
    hour   = +row.value[7]
    if month isnt 9 or not  14 <= day <= 28 then continue
    if temp > 50
      plotDataTemp['' +  day+hour/24.toFixed 3] = temp
    if lastDay and lastDay isnt day
      pc =  100* dayMins/60/24.toFixed 3
      plotDataPercent['' +  lastDay+0] = pc
      plotDataPercent['' +  lastDay+1 + '.0'] = pc
      kwHrs +=  dayMins / 60 * 3
      dayMins = 0
    lastDay = day
    dayMins += acMins
  plotDataPercent['' +  lastDay+0.5] =  100* dayMins/60/24.toFixed 3
  
  log 'last-half september kwHrs', Math.ceil kwHrs
  costPerKwHr = 400/kwHrs
  log 'cost/kwhr', costPerKwHr.toFixed 3
  
  plot
    data:      maxTemp: plotDataTemp, percentAC: plotDataPercent
    filename: 'stats/tempMinsSep.png'
    
  plotDataTemp = {}
  plotDataPercent = {}
  lastDay = null
  dayMins = kwHrs = 0
  days = 0
  
  for row in data.rows
    acMins = +row.value[1] 
    temp   = +row.value[3]
    month  = +row.value[5]
    day    = +row.value[6]
    hour   = +row.value[7]
    if month isnt 10 then continue
    if temp > 50
      plotDataTemp['' +  day+hour/24.toFixed 3] = temp
    if lastDay and lastDay isnt day
      plotDataPercent['' +  lastDay+0.5] = 
         100* dayMins/60/24.toFixed 3
      kwHrs +=  dayMins / 60 * 3
      days++
      dayMins = 0
    lastDay = day
    dayMins += acMins
  plotDataPercent['' +  lastDay+0.5] =  100* dayMins/60/24.toFixed 3

  log 'october kwHrs for', days, 'days:', Math.ceil kwHrs
  log 'october cost  for', days, 'days:', Math.ceil costPerKwHr * kwHrs
  log 'estimated october bill:', Math.ceil 31 *  costPerKwHr * kwHrs / days

  plot
    data:      maxTemp: plotDataTemp, percentAC: plotDataPercent
    filename: 'stats/tempMinsOct.png'
###
