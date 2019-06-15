# out: ../lib/index.js
"use strict"

http = require "http"
url  = require "url"
path = require "path"
debug = require "debug"
debug = debug "report-viewer"
spawn = require "child_process"
spawn = spawn.spawn

socketio = require "socket.io"
module.exports = (program) ->
  currentConsole = []

  # args processing
  port = program.port or 9999
  program.viewer ?= require("report-viewer-default")
  throw new Error "no files to serve" if not program.viewer.files
  site = program.viewer
  # options for client
  addOptionsToClient = ->
    site.files["options.js"] = "(function(){window.options={port:#{port}};}())"
  addOptionsToClient()
  # http server
  server = http.createServer (request,response) ->
    filename = url.parse(request.url).pathname.slice(1) or "index.html"
    if site.files[filename]
      debug "http server sending "+filename
      extension = path.extname(filename).slice 1
      extension = "javascript" if extension == "js"
      response.writeHead(200,{"Content-type":"text/"+extension})
      response.write(site.files[filename], "utf8")
    else
      response.writeHead(404,{"Content-type":"text/plain"})
      response.write("404", "utf8")
    response.end()

  # io server
  loaded = false
  io = socketio(server)
  io.on "connection", (socket) ->
    debug socket.id+" socket connected"
    socket.on "getConsole", () ->
      debug socket.id+" sending console cache"
      socket.emit "getConsole", currentConsole
    socket.on "setConsole", (newConsole) ->
      debug socket.id+" test ended. Updated console cache"
      currentConsole = newConsole
    socket.on "loaded", ->
      debug socket.id+" Website loaded successfully"
      loaded = true
      close() if ended
    socket.on "restartable", ->
      debug socket.id+" sending restartable: "+program.args.length > 0
      socket.emit "restartable", program.args.length > 0
    if program.args.length > 0
      debug socket.id+" client requests restart of child process"
      if restart
        socket.on "restart", restart

  # input management
  ended = false
  child = null
  dataManager = (chunk) ->
    if chunk != null
      lines = chunk.split("\n")
      lines.pop() if lines[lines.length-1] == ""
      for line in lines
        cLine = {}
        cLine.id = currentConsole.length
        cLine.text = line
        cLine.type = "normal"
        io.emit "consoleLine", cLine
        currentConsole.push cLine
  # if input over stdin
  if program.args.length == 0
    process.stdin.on 'end', (chunk) ->
      debug "input closed"
      ended = true
      close() if loaded
    process.stdin.setEncoding("utf8")
    process.stdin.on "data", dataManager
  else # if input over own command
    restart = () ->
      currentConsole = []
      io.emit "restart"
      child.kill() if child
      sh = "sh"
      args = ["-c"]
      if process.platform == "win32"
        sh = "cmd"
        args[0] = "/c"
      args = args.concat program.args
      child = spawn sh, args, {
        cwd: process.cwd(),
        env: process.env
      }
      child.stdout.setEncoding("utf8")
      child.stdout.on "data", dataManager
      child.stderr.setEncoding("utf8")
      child.stderr.on "data", dataManager

    restart()



  # starting server
  console.log "serving on port "+port
  server.listen(port)

  # args execution
  if program.opener
    debug "opening browser"
    opener = require "opener"
    opener("http://localhost:"+port)
  else
    debug "issue reload to clients"
    io.sockets.emit "reload"

  # for developing own views
  if site.action
    site.action.on "reload", () ->
      addOptionsToClient()
      debug " View changed - reloading"
      io.sockets.emit "reload"

  # close
  close = () ->
    debug "exit process"
    child.kill() if child
    server.close()
    process.exit()
