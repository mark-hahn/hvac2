
util = require 'util'

{render, doctype, html, head, title, body, component, \
 div, script, style, text} = require 'teacup'

noNet = 'noNet = false'

allStyles = '
  html {box-sizing: border-box}
  *, *:before, *:after {box-sizing: inherit}
  body {
    font-family:tahoma;
    overflow: hidden;
  }
  .page {
    overflow: hidden;
    display:none;
    background-color: gray;
  }
  .tvroom {
    width: 100%;
    height: 50%;
    position: relative;
    top: 0;
    left: +5%;
  }
  .backyard {
    width: 100%;
    height: 50%; 
    border:1px solid red;
  }
  .toprow {
    display: inline-block;
    width:100%;
    height: 50%;
  }
  .botrow {
    display: inline-block;
    width: 100%;
    height: 50%;
    position: relative;
    top: -5%;
  }  
  .light {
    display: inline-block;
    width: 20%;
    height: 50%;
    margin: 6%;
  }
  .topLight {
    width:80%;
    height:75%;
    border-radius: 50%;
    border:1px solid red;
    background-color: white;
  }
  .botLight {
    width:80%;
    height:75%;
    border-radius: 50%;
    border:1px solid red;
    background-color: black;
  }
' 

light = component (bulb) ->
  div '.light', ->
    div '.topLight'+bulb, ->
    div '.botLight'+bulb, ->

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
            div '.toprow', ->
              light '.left'
              light '.middle'
              light '.right'
            div '.botrow', ->
              light '.left'
              light '.middle'
              light '.right'
          div '.backyard', ->
          



        script src: 'js/lights-client.js'
