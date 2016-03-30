
util = require 'util'

{render, doctype, html, head, title, base, body, component, \
 div, script, style, text, hr} = require 'teacup'

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
    height: 55%;
    position: relative;
    left: +5%;
  }
  .deck {
    width: 100%;
    height: 20%; 
    position: relative;
    left: +5%;
  }
  .patio {
    width: 100%;
    height: 20%; 
    position: relative;
    left: +5%;
  }
  .allrow {
    position: absolute;
    left: 33%;
    height: 20%;
    width: 50%;
  }  
  .toprow {
    display: inline-block;
    width:100%;
    height: 45%;
    position: relative;
    top: 19%;
  }
  .botrow {
    display: inline-block;
    width: 100%;
    height: 45%;
    position: relative;
    top: 13%;
  }  
  .light {
    display: inline-block;
    width: 20%;
    height: 50%;
    margin: 6%;
  }
  .deck .light {
    display: inline-block;
    width: 20%;
    height: 60%;
    margin: 6%;
    position: relative;
    top: -11%;
    left:32%;
  }
  .patio .light {
    display: inline-block;
    width: 20%;
    height: 60%;
    margin: 6%;
    position: relative;
    top: -11%;
    left:32%;
  }
  .rowTitle {
    position:absolute;
    top:10%;
    font-size:1.2rem;
    font-weight:bold;
    color:white;
  }
  .tvroom .rowTitle {
    top: 8%;
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
  .allrow .light{
    width: 100%;
    height: 90%;
  }
  .allrow .botLight{
    float:left;
    width:50%;
    height:80%;
  }
  .allrow .topLight{
    float:right;
    width:50%;
    height:80%;
  }
  .invis {
    visibility: hidden;
  }
  .dimBtn {
    width: 25%;
    height: 50%;
    margin: 1%;
    border: 1px solid red;
    text-align: center;
    position: absolute;
    left: 64%;
    top: 20%;
    font-size: 1rem;
    font-weight: bold;
    padding-top: 4%;
    background-color: #aaa;
    border-radius: 10%;
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
        base href:"http://hahnca.com/lights/"
        style  allStyles
        script noNet
      body ->
        div '.page', ->
          div '.tvroom', ->
            div '.rowTitle', 'TV Room'
            div '.allrow', ->
              light '.all'
            div '.toprow', ->
              light '.left'
              light '.middle'
              light '.right'
            div '.botrow', ->
              light '.left'
              light '.middle'
              light '.right'
          hr style: 'margin:1%'
          div '.deck', ->
            div '.rowTitle', 'Deck'
            light '.bbq'
            light '.table'
          hr style: 'margin:1%'
          div '.patio', ->
            div '.rowTitle', 'Patio'
            light '.lights'
            div '.dimBtn', 'Dim ^'

        script src: 'js/lights-client.js'
