
util = require 'util'

{render, doctype, html, head, title, base, body, div, script, raw, text} = require 'teacup'

module.exports = ->
  render ->
    doctype()
    html ->
      head ->
        title 'tvtab'
        base href:"http://hahnca.com/tvtab/"
      body style:'background-color:black; color:white;
                  font-size:200px; 
                  font-family:tahoma', ->
# outer rim
        div style:'width:800px; height:1280px;  
                   position:relative; border:1px solid red;', ->
# time
          div '#time', style:'width:100%; text-align:center;  top:35px;  padding-bottom:50px;
                            position:relative;'
# date
          div style:'font-size:150px', ->
            div '#date', style:'width:100%; text-align:center; position:relative; padding-bottom:50px; padding-top: 30px;'
            
# divider 
          div '.divider', style:'width:100%; height:2px; margin-top:20px; margin-bottom:20px; background-color:#ccc;'

          div style:'font-size:130px; display:flex; justify-content: space-around; width:800px; margin-top: 30px; height:185px', ->
# temp                
            div style:'display:flex', ->      
              div '#tvRoom'
              div style:'font-size:80px', ->
                raw '&#176;'
# setpoint                        
            div style:'display:flex', ->      
              div '#tvRoomSetpoint'
              div style:'font-size:80px', ->
                raw '&#176;'
# divider 
          div '.divider', style:'width:100%; height:2px; margin-top:20px; margin-bottom:20px; background-color:#ccc;'

# other rooms
          div style:'font-size:120px; display:flex; justify-content: space-around; width:800px; position:relative; top:10px; height: 110px; padding-bottom:50px; padding-top: 30px;', ->
            div style:'display:flex', ->      
              text 'M'
              div '#master'
              div style:'font-size:60px', ->
                raw '&#176;'
            div style:'display:flex', ->      
              text 'S'
              div '#kitchen'
              div style:'font-size:60px', ->
                raw '&#176;'
            div style:'display:flex', ->      
              text 'G'
              div '#guest'
              div style:'font-size:60px', ->
                raw '&#176;'

# divider 
          div '.divider', style:'width:100%; height:2px; margin-top:20px; margin-bottom:20px; background-color:#ccc;'

# weather
          div style:'font-size:130px; display:flex; justify-content: space-around; width:800px;     margin-top: 30px; height:200px', ->
            div style:'display:flex', ->      
              div '#outTemp'
              div style:'font-size:80px', ->
                raw '&#176;'
            div style:'display:flex', ->      
              div '#outHumidity'
              div style:'font-size:50px; position:relative; top:10px;', ->
                raw '%'
            div style:'display:flex', ->      
              div '#windGust'
              div style:'font-size: 30px; position: relative; top: 10px; left: 2px;', ->
                text 'mph'
            div style:'display:flex', ->      
              div '#rain'
              div style:'font-size:50px; position: relative; top: 10px; ', ->
                raw '"'
        script src: '/ceil/js/jquery-2.1.4.js'
        script src: '/ceil/js/moment.js'
        script src: '/ceil/js/primus.js'
        script src: '/ceil/js/tvtab-client.js'
        script src: '/ceil/js/websock-client.js'
