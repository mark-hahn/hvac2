
util = require 'util'

{render, doctype, html, head, title, body, div, img, raw, text, script} = require 'teacup'

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
                     overflow:hidden; margin-bottom:20px', ->
           div '#master', style:'display:inline-block; float:left; width:880px'
           div style:'display:inline-block; float:right; font-size:250px; width:620px', ->
             div '#masterSetpoint', style:'position:relative; float:right; 
                                           top:30px; width:100%; text-align:right'
             div '#masterCode',  
                  style: 'position: relative; float: right; width:100%;
									        top: -15px; font-size: 150px; text-align:right'
		
          div '#divider', style:'width:100%; height:6px; overflow:hidden;
                                 background-color:white; position:relative; top:20px;'

          div style:'position:relative; width:100%; height:430px; top:0px; overflow:hidden', ->
           div '#time', style:'display:inline-block; float:left; width:880px'
           div style:'display:inline-block; float:right; font-size:250px; width:620px', ->
              div '#outside', style:'position:relative; float:right; 
                                     top:30px; width:100%; text-align:right'
              div '#sysCode',  
                  style: 'position: relative; float: right; width:100%;
									        top: -15px; font-size: 150px; text-align:right'

        script src: 'js/jquery-2.1.4.js'
        script src: 'js/moment.js'
        script src: 'js/primus.js'
        script src: 'js/ceil-client.js'
        script src: 'js/websock-client.js'
