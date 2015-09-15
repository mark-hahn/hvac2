
util = require 'util'

{render, doctype, html, head, title, body, div, hr, script} = require 'teacup'

module.exports = ->
  render ->
    doctype()
    html ->
      head ->
        title 'ceil'
      body style:'background-color:black; color:white;
                  font-size:420px; text-align:center;
                  font-family:tahoma', ->

        div style:'width:1520px; height:1000px; padding:150px; position:relative', ->

          div style:'width:100%; height:430px; position:relative;
                     overflow:hidden; margin-bottom:0', ->
                       
           div '#master', style:'display:inline-block; float:left; width:880px;
                                position:relative; top:-40px; text-align: center;'
           
           div style:'display:inline-block; float:right; font-size:250px; width:620px;
                      border-left:6px solid #ccc', ->
                        
             div '#masterSetpoint', style:'position:relative; float:right; top:-25px; 
                                    width:100%; height:250px; text-align:center'
                                           
             hr style: "height:6px; margin:0; color: #ccc"
             
             div '#masterCode',  
                  style: 'position: relative; float: right; width:100%; color:#ccc;
									        top: -15px; font-size: 150px; text-align:center'
		
          div '#divider', style:'width:100%; height:6px; overflow:hidden; margin:0;
                                 background-color:#ccc; position:relative; top:0;'

          div style:'position:relative; width:100%; height:430px; top:0px; overflow:hidden', ->
            
           div '#time', style:'display:inline-block; float:left; 
                               width:1080px; text-align:center;'
           
           div style:'display:inline-block; float:right; font-size:250px; width:420px;
                      border-left:6px solid #ccc', ->
                        
              div '#outside', style:'position:relative; float:right; top:-25px; 
                                     width:100%; height:250px; text-align:center'
                                     
              hr style: "height:6px; margin:0; color: #ccc"
              
              div '#sysCode',  
                  style: 'position: relative; float: right; width:100%;
									        top: 0; font-size: 150px; text-align:center; color:#ccc'

        script src: 'js/jquery-2.1.4.js'
        script src: 'js/moment.js'
        script src: 'js/primus.js'
        script src: 'js/ceil-client.js'
        script src: 'js/websock-client.js'
