
util = require 'util'

{render, doctype, html, head, title, base, body, div, script, raw, text} = require 'teacup'

module.exports = ->
  render ->
    doctype()
    html ->
      head ->
        title 'mbtab'
        base href:"http://hahnca.com/mbtab/"
      body style:'background-color:black; color:white;
                  font-size:150px; 
                  font-family:tahoma', ->

# time/date row
        div style:'display:flex; 
                   justify-content: space-around;', ->      
          div style:'display:flex', ->      
            div '#time', style:'font-size:150px'
          div style:'display:flex; flex-direction: column;
                     font-size:75px; ', ->      
            div style:'display:flex', ->      
              div '#date'
            div style:'display:flex; flex-direction: row;
                       justify-content: flex-end', ->      
              div '#masterOnOff', style:'display:flex'

# divider 
        div '.divider', style:'width:100%; height:2px; margin-top:20px; margin-bottom:20px; background-color:#ccc;'


# indoor row     
        div style:'font-size:100px; display:flex; justify-content: space-around; width:100%; margin-top: 20px; height:120px', ->
          # master temp           
          div style:'display:flex', ->      
            div '#master'
            # div style:'font-size:80px', ->
            #   raw '&#176;'

          # master setpoint                        
          div style:'display:flex', ->      
            div '#masterSetpoint'
            # div style:'font-size:80px', ->
            #   raw '&#176;'

          # tv room                        
          div style:'display:flex', ->      
            # text 'T'
            div '#tvRoom'
            # div style:'font-size:60px', ->
            #   raw '&#176;' # degree symbol

          # tv room                        
          div style:'display:flex', ->      
            # text 'S'
            div '#kitchen'
            # div style:'font-size:60px', ->
            #   raw '&#176;' # degree symbol

          # tv room                        
          div style:'display:flex', ->      
            # text 'G'
            div '#guest'
            # div style:'font-size:60px', ->
            #   raw '&#176;' # degree symbol
              
# divider 
        div '.divider', style:'width:100%; height:2px; margin-top:20px; margin-bottom:20px; background-color:#ccc;'

# outside weather
        div style:'font-size:100px; display:flex; justify-content: space-around; width:100%; position:relative; top:10px; height: 110px; padding-bottom:50px; padding-top: 10px;', ->
          div style:'display:flex', ->      
            div '#outTemp'
            # div style:'font-size:80px', ->
            #   raw '&#176;' # degree symbol
          div style:'display:flex', ->      
            div '#outHumidity'
            # div style:'font-size:50px; position:relative; top:10px;', ->
            #   raw '%'
          div style:'display:flex', ->      
            div '#windGust'
            # div style:'font-size: 30px; position: relative; top: 10px; left: 2px;', ->
            #   text 'mph'
          div style:'display:flex', ->      
            div '#windGustDir'
          div style:'display:flex', ->      
            div '#rain'
            # div style:'font-size:50px; position: relative; top: 10px; ', ->
            #   raw '"'

              
      script src: '/mbtab/js/jquery-2.1.4.js'
      script src: '/mbtab/js/moment.js'
      script src: '/mbtab/js/primus.js'
      script src: '/mbtab/js/mbtab-client.js'
      script src: '/mbtab/js/websock-client.js'
