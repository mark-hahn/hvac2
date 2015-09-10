
moment = require 'moment'

logWithTime = (args...) -> 
  time = moment().format 'MM-DD HH:mm:ss'
  console.log time, args...

module.exports = (module) ->

  log: (args...) -> 
    logWithTime module.toLowerCase() + ' ', args...
    
  logObj: (title, obj) -> 
    msg = title + ':'
    for k,v of obj
      if typeof v is 'string'
        if v isnt 'off'
          msg += k + '(' + v + ')'
        continue
        
      if v then msg += ' ' + k
      
      if v is  1 then msg += '(1)'
      if v is -1 then msg += '(-1)'
    logWithTime module.toLowerCase() + ' ', msg
