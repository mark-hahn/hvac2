
module.exports = 
  
  fmtobj: (title, obj) ->
    msg = title + ':'
    for k,v of obj
      if typeof v is 'string'
        if v isnt 'off'
          msg += k + '(' + v + ')'
        continue
        
      if v then msg += ' ' + k
      
      if v is  1 then msg += '(1)'
      if v is -1 then msg += '(-1)'
    msg
