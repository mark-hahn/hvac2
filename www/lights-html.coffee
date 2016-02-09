
util = require 'util'

{render, doctype, html, head, title, body, div, script} = require 'teacup'

module.exports = ->
  render ->
    doctype()
    html style: 'box-sizing: border-box; font-size: 12px', ->
      head ->
        title 'lights'
        style: '*, *:before, *:after {box-sizing: inherit}'
        
      body style:'font-size:320px; 
                  font-family:tahoma', ->
        div '.page', style: 'border:1px solid red', ->
          



        script src: 'js/lights-client.js'
