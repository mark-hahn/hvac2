
log = console.log.bind console
db = require('nano') 'http://localhost:5984/hvac'
readline = require 'linebyline'

put = (doc, cb) ->
  db.get doc._id, (err, readVal) ->
    if readVal?._rev then doc._rev = readVal._rev
    # log 'put: ---->', doc._id, doc.type
    db.insert doc, (err) ->
      if err?.statusCode is 409
        put doc, cb
        return
      if err then log 'db put err:', err; cb? err; return
      cb?()

lineRegex = /// ^
            (\d\d)/(\d\d)\s+                  # mo day
            (\d\d):(\d\d):(\d\d)\.(\d\d)\s+   # hr min sec hundreds
            (-|C|H|F)(-|C|H|F)\s+             # sysmode actualSysMode
            (i|r|e)                           # extAir
            (\d\d)-(\d\d)                     # halltemp outsidetemp
            ///i
            
parseLine = (line) ->
  if not (match = lineRegex.exec line) then return null
  [__, mo, day, hr, min, sec, hundreds, 
       sysMode, actualSysMode, extAir, hallTemp, extTemp] = match  
  {mo, day, hr, min: +min, sec: +sec, hundreds: +hundreds,          \
    sysMode, actualSysMode, extAir: (extAir.toLowerCase() is 'e'),  \
    hallTemp: +hallTemp, extTemp: +extTemp}

lines = []

finish = ->
  samples = acSecs = totalExtTemp = maxTemp = 0
  minTemp = 1000
  lastId = null
  
  clearStats = ->
    samples = acSecs = totalExtTemp = maxTemp = 0
    minTemp = 1000

  addToStats = (nextElapsed = 5, line) ->
    samples++
    maxTemp = Math.max maxTemp, line.extTemp
    minTemp = Math.min minTemp, line.extTemp
    totalExtTemp += line.extTemp
    if line.actualSysMode in ['C', 'c']
      acSecs += nextElapsed
      
  hrBreak = (cb) ->
    if lastId
      doc = {
        type: 'hour'
        _id:   lastId
        year:  '20' + lastId[ 5.. 6]
        month: lastId[ 8.. 9]
        day:   lastId[11..12]
        hour:  lastId[14..15]
        samples 
        acSecs: Math.ceil acSecs
        avgExtTemp: Math.round totalExtTemp / samples
        minExtTemp: minTemp
        maxExtTemp: maxTemp
      }
      log 'saving ' + doc._id
      put doc, (err) ->
        if err 
          log 'exiting ...'
          process.exit 1
        clearStats()
        cb?()
    else 
      cb?()

  do oneLine = ->
    if not (line = lines.shift()) then hrBreak(); return

    nextLine = lines[0]
    id = "hour:15-#{line.mo}-#{line.day}-#{line.hr}"
    time = line.min * 60 + line.sec + (line.hundreds) / 100 
    nextElapsed = null
    if nextLine and 
        id is "hour:15-#{nextLine.mo}-#{nextLine.day}-#{nextLine.hr}" 
      nextTime = nextLine.min * 60 + nextLine.sec + (nextLine.hundreds) / 100 
      nextElapsed = nextTime - time
    if id isnt lastId
      hrBreak ->
        lastId = id
        addToStats nextElapsed, line
        oneLine()
      return
    addToStats nextElapsed, line      
    oneLine()

files = ['/root/logs/hvac.log']
# files = ['/root/logs/hvac.log', '/root/logs/hvac2-dev.log', 
        #  '/root/apps/hvac/nohup.out', '/root/dev/apps/hvac2/nohup.out']

do oneFile = ->
  if not (file = files.shift()) 
    finish()
    return
    
  lr = readline file

  dbgLastDay = null
  lr.on 'line', (line) ->
    if (lineData = parseLine line)
      day = "#{lineData.mo}-#{lineData.day}"
      if not dbgLastDay
        log 'first:', day
      dbgLastDay = day
      lines.push lineData
     
  lr.on 'close', ->
    log 'last:', dbgLastDay
    log 'read', lines.length, 'lines'
    oneFile()
