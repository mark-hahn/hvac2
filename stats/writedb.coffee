
log = console.log.bind console
db = require('nano') 'http://localhost:5984/hvac'
readline = require 'linebyline'

log ''
log 'writedb started', new Date().toString()[0..23], '\n'

put = (doc, cb) ->
  # db.get doc._id, (err, body) ->
  #   if err 
  #     # log 'db.get err', doc._id, err
  #     cb?()
  #     return
  #   # if doc._id is 'hour:15-10-30-20'
  #   #   log body
  #   db.destroy doc._id, body._rev, (err, body) ->
  #     if err then log 'db.destroy err', doc._id, err
  #     cb?()

  db.head doc._id, (err, __, headers) ->
    # if err then log 'db.head err', err
    if err?.statusCode is 404 or err?.code is 'ENOENT'
      db.insert doc, (err) ->
        if err?.statusCode is 409
          put doc, cb
          return
        if err then log 'writedb db put err:', err; cb? err; return
        cb?()
      return
    cb?()

    
lineRegex = /// ^
            (\d\d)/(\d\d)\s+                  # mo day
            (\d\d):(\d\d):(\d\d)\.(\d\d)\s+   # hr min sec hundreds
            (-|C|H|F)(-|C|H|F)\s+             # sysmode actualSysMode
            (i|r|e)                           # extAir
            (\d\d)-(--|\d\d)                  # halltemp outsidetemp
            ///i
            
parseLine = (line) ->
  if not (match = lineRegex.exec line) then return null
  # if line[0..1] is '11' then log line
  [__, mo, day, hr, min, sec, hundreds, 
       sysMode, actualSysMode, extAir, hallTemp, extTemp] = match 
  {mo, day, hr, min: +min, sec: +sec, hundreds: +hundreds,          \
    sysMode, actualSysMode, extAir: (extAir.toLowerCase() is 'e'),  \
    hallTemp: +hallTemp, extTemp: +extTemp}

lines = []
lineCount = 0

processLines = ->
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
      # log 'acSecs', line.actualSysMode, acSecs, nextElapsed
      
  hrBreak = (cb) ->
    if lastId
      # log 'acSecs', acSecs
      doc = {
        type: 'hour'
        _id:   lastId
        year:  +('20' + lastId[ 5.. 6])
        month: +lastId[ 8.. 9]
        day:   +lastId[11..12]
        hour:  +lastId[14..15]
        samples 
        acSecs: Math.ceil acSecs
        avgExtTemp: Math.round totalExtTemp / samples
        minExtTemp: minTemp
        maxExtTemp: maxTemp
      }
        
      if doc.hour is 0
        log 'writing to db:', doc.year, doc.month, doc.day
        
      # if doc.year is 2015 and doc.month is 10 and doc.day is 30
        # log 'writing to db:', doc.year, doc.month, doc.day, doc.hour, doc.acSecs
        
      # log 'saving ' + doc._id
      put doc, (err) ->
        if err 
          log 'writedb exiting ...', new Date().toString()[0..23], '\n'
          process.exit 1
        clearStats()
        cb?()
    else 
      cb?()

  do oneLine = ->
    if not (line = lines.shift()) 
      log 'writedb finished', lineCount, 'of', lines.length, 'lines', 
                      new Date().toString()[0..23], '\n'
      return

    # if +line.mo < 11 then process.nextTick oneLine; return
    if +line.mo < 11 and +line.day < 27 then process.nextTick oneLine; return
      
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
# files = ['/root/logs/hvac.log'
        #  '/root/apps/hvac/nohup.out'
        #  '/root/dev/apps/hvac2/nohup.out'
        # ]

do oneFile = ->
  if not (file = files.shift()) 
    log 'writedb finished reading files', new Date().toString()[0..23], '\n'
    processLines()
    return
  
  linesFromFile = 0
  
  lr = readline file

  firstDayInLog = null
  lastDayInLog = null
  lr.on 'line', (line) ->
    if (lineData = parseLine line)
      day = "#{lineData.mo}-#{lineData.day}"
      firstDayInLog ?= day
      lastDayInLog = day
      linesFromFile++
      lines.push lineData
     
  lr.on 'error', (err) ->
    log 'writedb line reader err', err
    oneFile()
    
  lr.on 'close', ->
    log 'writedb: read', file, 'with', linesFromFile, 'lines covering', 
                firstDayInLog, 'to', lastDayInLog
    # log lines[-2...]
    oneFile()
