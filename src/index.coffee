"use strict"

express = require "express"
http = require "http"
path = require "path"
xmlparser = require("xml2json").toJson
inspect = require('util').inspect;

module.exports = (args) ->
  port = args.port or 9999
  currentData = []
  buffer = ""
  parsers = {
    json: (chunk) ->
      chunk = process.stdin.read()
      if chunk != null
        data = false
        try
          data = JSON.parse(chunk)    
        if data
          if data[0] == "start"
            currentData = [data]
          else 
            currentData.push data
          io.sockets.emit("singleData",data)
        else
          console.log chunk
    xunit: (chunk) ->
      parse = () ->
        data = xmlparser(buffer,{object:true})
        currentData = [["start",{"total":data.testsuite.tests}]]
        for test in data.testsuite.testcase
          item = {
            title: test.name
            fullTitle: test.classname + " "+ test.name
            duration: test.time*1000
          }
          if test.failure
            item.failure = test.failure
            .replace(/&amp;lt;/g,"<")
            .replace(/&amp;gt;/g,">")
            .replace(/&amp;&amp;#35;40;/g,"(")
            .replace(/&amp;&amp;#35;41;/g,")")
            .replace(/&apos;/g,"'")
            item = ["fail",item]
          else
            item = ["pass",item]
          currentData.push(item)
        currentData.push(["end",{
          tests: data.testsuite.tests
          failures: data.testsuite.failures            
          duration: data.testsuite.time*1000
          }])
        io.sockets.emit "data", currentData
      chunk = process.stdin.read()
      if chunk != null
        match = false
        if /^<testsuite/.test(chunk)
          buffer = chunk
        else if /^<testcase/.test(chunk)
          buffer += chunk
          if /<\/testsuite>/.test(chunk)
            parse()
        else if /^<\/testsuite>/.test(chunk)
          buffer += chunk
          parse()
        else
          console.log chunk
  }
  reporter = args.reporter or "xunit"
  if parsers[reporter]
    parser = parsers[reporter]
  else
    parser = parsers.xunit
  app = express()
  app.set "port", port
  if process.env.dirname
    dir = process.env.dirname
  else
    dir = path.join(__dirname,"..")
  appdir = path.join(dir, "ngapp")
  ## setting static routes
  app.use express.static(appdir)
  app.use "/vendor", express.static(path.join(dir, "vendor"))
  server = app.listen app.get("port"), ->
    console.log "Express server listening on port %d in %s mode", app.get("port"), app.get("env")
  io = require("socket.io")(server)
  process.stdin.setEncoding('utf8')
  
  process.stdin.on 'readable', parser
    
  io.on "connection", (socket) -> 
    console.log "socket.io client connected"
    socket.on "data", () ->
      socket.emit "data", currentData
    socket.on "livereload", () ->
      console.log "sending "+ args.livereload
      socket.emit "livereload", args.livereload
  process.stdin.on 'end', -> server.close()
  if args.open
    opener = require "opener"
    opener("http://localhost:"+port)
  if args.livereload
    lrserver = require "live-reload"
    lrserver({
      port: args.livereload,
      _: [appdir],
      })