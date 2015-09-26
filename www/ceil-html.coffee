
util = require 'util'

{render, doctype, html, head, title, body, div, script} = require 'teacup'

module.exports = ->
  render ->
    doctype()
    html ->
      head ->
        title 'ceil'
      body style:'background-color:black; color:white;
                  font-size:320px; 
                  font-family:tahoma', ->
# outer rim
        div style:'width:1570px; height:760px;  
                   position:relative; border:1px solid red;', ->
# top half
          div style:'width:100%; height:300px; position:relative;', ->
  # temp                       
           div '#master', style:'width:850px; text-align:right;  height: 400px;
                                position:relative; top:-40px; '
  # setpoint container         
           div style:'position:absolute; top:0px; right:30px; font-size:250px;', ->
    # setpoint                        
             div '#masterSetpoint', style:'top:-20px; width:100%; 
                                           position: relative;'
# main divider             
          div '#divider', style:'width:100%; height:6px; margin:0; background-color:#ccc;'
# bot half
          div style:'position:relative; width:100%; height:300px; top:0px;', ->
  # time            
           div '#time', style:'height:400px; width:850px; text-align:right; top:-40px;
                               position:relative;'
  # outside temp         
           div style:'position:absolute; top:0px; right:20px; 
                     font-size:250px; width:280px; height:300px;', ->
                        
              div '#outside', style:'position:relative; float:right; top:-25px; 
                                     width:100%; height:250px; '
                                     
# bottom divider                            
          div '#divider', style:'width:100%; height:6px;  margin:0; background-color:#ccc;'
            
          div '#codes', ->
            
              div '#sysCode',  
                  style: 'position: relative; float: left; width:50%;
									        top: 0; font-size: 150px; text-align:center;
                          font-family: Courier, monospace;'
                          
              div '#masterCode',  
                  style: 'position: relative; float: right; width:50%;
									        top: -15px; font-size: 150px; text-align:center'
		

        script src: 'js/jquery-2.1.4.js'
        script src: 'js/moment.js'
        script src: 'js/primus.js'
        script src: 'js/ceil-client.js'
        script src: 'js/websock-client.js'
