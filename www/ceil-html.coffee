
util = require 'util'

{render, doctype, html, head, title, base, body, div, script} = require 'teacup'

module.exports = ->
  render ->
    doctype()
    html ->
      head ->
        title 'ceil'
        base href:"http://hahnca.com/ceil/"
      body style:'background-color:black; color:white;
                  font-size:320px; 
                  font-family:tahoma', ->
# outer rim
        div style:'width:1570px; height:760px;  
                   position:relative; border:1px solid red;', ->
# top half
          div onClick:'bumpTemp("up")', \
              style:'width:100%; height:300px; position:relative;', ->
  # temp                       
           div '#master', style:'width:820px; text-align:right;  height: 400px;
                                position:relative; top:-40px; '
  # setpoint container         
           div style:'position:absolute; top:0px; right:30px; font-size:250px;', ->
    # setpoint                        
             div '#masterSetpoint', style:'top:-20px; width:100%; 
                                           position: relative;'
# main divider             
          div '#divider', style:'width:100%; height:6px; margin:0; background-color:#ccc;'
          
# bot half
          div onClick:'bumpTemp("down")', \
              style:'position:relative; width:100%; height:300px; top:0px;', ->
  # time            
           div '#time', style:'height:400px; width:820px; text-align:right; top:-40px;
                               position:relative;'
           div '#divider', style:'position:absolute; top:-300px; left:857px; height:750px; 
                                  width:6px; margin:0; background-color:#ccc;'
  # outside temp         
           div '#wx1', style:'position:absolute; top:-20px; right:350px; 
                             font-size:220px; width:350px; height:450px;', ->
              div '#outTemp', style:'position:absolute; top:0px;      right:20px;'
              div '#rain',    style:'position:absolute; bottom:-25px; right:20px;'
              
           div '#wx2', style:'position:absolute; top:-20px; right:0; 
                             font-size:220px; width:350px; height:450px;', ->
              div '#outHumidity', style:'position:absolute; top:0px;      right:20px;'
              div '#windGust',    style:'position:absolute; bottom:-25px; right:20px;'
                                     
# bottom divider                            
          div '#divider', style:'width:55%; height:6px; 
                                 margin:0; background-color:#ccc;'
            
          div '#codes', style:'position:relative; font-size: 130px;
                               width: 800px; height:150px;
                               font-family: Arial, sans-serif;', ->
            
              div '#sysCode', style: 'position: absolute; left:35px; top: 0;'
									                    
              div '#masterCode', style: 'position: absolute; right:0; top: 0; 
                                         text-align: center;'

        script src: 'js/jquery-2.1.4.js'
        script src: 'js/moment.js'
        script src: 'js/primus.js'
        script src: 'js/ceil-client.js'
        script src: 'js/websock-client.js'
