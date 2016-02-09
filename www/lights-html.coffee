
util = require 'util'

{render, doctype, html, head, title, body, component, \
 div, script, style, text} = require 'teacup'

noNet = 'noNet = true'

allStyles = '
  html {box-sizing: border-box}
  *, *:before, *:after {box-sizing: inherit}
  body {font-family:tahoma}
  .page {
    display:none;
  }
  .tvroom {
    width: 86%;
    height: 50%;
    border:1px solid red;
  }
  .backyard {
    width: 86%;
    height: 50%; 
    border:1px solid red;
  }
  .light {
    border: 1px solid blue;
    width: 20%;
    height: 20%;
  }
' 

light = component () ->
  div '.light', ->
    text 'hello world'

module.exports = ->
  render ->
    doctype()
    html ->
      head ->
        title 'lights'
        style  allStyles
        script noNet
      body ->
        div '.page', ->
          div '.tvroom', ->
            light()
          div '.backyard', ->
          



        script src: 'js/lights-client.js'
