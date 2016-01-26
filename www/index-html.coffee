
util = require 'util'

{render, doctype, html, head, title, meta, 
 body, div, img, raw, text, script} = require 'teacup'

module.exports = ->
  render ->
    doctype()
    html ->
      head ->
        title 'thermostat'
        # meta name: "viewport", \
        #      content: "width=device-width; height=device-height;
        #                initial-scale=1.0; maximum-scale=1.0; 
        #                user-scalable=no; user-scalable=0;"

      body style: "overflow:hidden;
            -webkit-touch-callout: none;
            -webkit-user-select: none;
            -khtml-user-select: none;
            -moz-user-select: none;
            -ms-user-select: none;
            user-select: none;
            font-family: Sans-Serif;", ->
        div '#page', style: "position:absolute; overflow:hidden; display:none", ->
          div '#top', style: "clear:both; width:100%; height:25%;
                    background-color:#aaa; text-align:center; color:#666", ->
            div '#tvRoom.top',   room:'tvRoom',  style: "float:left; width:24%;
                                  clear:both;", 'TV'
            div '#kitchen.top', room:'kitchen', style: "float:left; width:24%", 'Sew'
            div '#master.top',  room:'master',  style: "float:left; width:24%", 'Mstr'
            div '#guest.top',   room:'guest',   style: "float:left; width:24%", 'Guest'

          div '#middle', style: "clear:both; background-color: #eee;
                      width:100%; height:50%", ->

            div '#left', style: "clear:both; float:left; 
                                 width:50%; height:100%; position: relative", ->
              div '#lftTemp', style: "clear:both; float:left; text-align: center;
                                      width:100%;"
              div '#codes', style: "position:absolute; right:1%; bottom:1%; 
                                    background-color:rgba(255, 247, 0, 0.28); 
                                               color:rgba(144, 63, 63, 0.63);
                                    padding:1%; border-radius: 20%; font-size: 20%;"

            div '#right', style: "float:left; width:50%; height:100%;
                        background-color: gray; color: white; ", ->

              div '#rgtTop', style: "clear:both; float:left;
                            font-style: bold;
                            background-color: red;
                            text-align: center;
                            width:100%; height:25%;", ->
                div '#rgtPlus', style: "clear:both; float:left;
                            font-weight: bold;
                            color: white; text-align: center;
                            width:100%; height:80%; ", '+'

              div '#rgtMid', style: "clear:both; float:left;
                          background-color: #ccc;
                          color: white; text-align: center;
                          width:100%; height:50%;", ->
                div '#rgtTemp', style: "clear:both; float:left;
                            color: #808; text-align: center;
                            width:100%;"

              div '#rgtBot', style: "clear:both; float:left;
                          font-style: bold;
                          background-color:blue; color:white;
                          text-align: center;
                          width:100%; height:25%;", ->
                div '#rgtMinus', style: "clear:both; float:left;
                            font-weight: bold;
                            color: white;  text-align: center;
                            width:100%; height:80%; ", '-'

          div '#bottom', style: "clear:both; width:100%; height:25%;
                    background-color:#aaa; text-align:center; color:#666", ->
            div '#off.bot',  mode:'off',  style: "float:left; width:24%; clear:both;",
                                             'Off'
            div '#fan.bot',  mode:'fan',  style: "float:left; width:24%;", 'Fan'
            div '#heat.bot', mode:'heat', style: "float:left; width:24%;", 'Heat'
            div '#cool.bot', mode:'cool', style: "float:left; width:24%;", 'Cool'

        script src: 'js/jquery-2.1.4.js'
        script src: 'js/primus.js'
        script src: 'js/teacup.js'
        script src: 'js/websock-client.js'
        script src: 'js/events.js'
        script src: 'js/tstat-client.js'
