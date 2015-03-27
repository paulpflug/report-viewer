"use strict"

http = require "http"
url  = require "url"
path = require "path"
events = require "events"

socketio = require "socket.io"
module.exports = (args) ->
  currentData = []
  currentConsole = []

  # args processing
  port = args.port or 9999
  parser = args.parser
  throw new Error "no viewer given" if not args.viewer
  throw new Error "no files to serve" if not args.viewer.files 
  site = args.viewer

  # process handling
  ended = false
  process.stdin.on 'end', -> 
    ended = true
    close() if loaded

  # http server
  server = http.createServer (request,response) ->
    filename = url.parse(request.url).pathname.slice(1) or "index.html"
    if site.files[filename]
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
    socket.on "data", () ->
      socket.emit "data", currentData
    socket.on "console", (console) ->
      socket.emit "console", currentConsole  
    socket.on "loaded", ->
      loaded = true
      close() if ended 
  if site.action
    site.action.on "reload", () ->
      io.sockets.emit "reload"

  # stdin processing
  process.stdin.setEncoding("utf8")
  actions = new events.EventEmitter()
     
  actions.on "data", (data) ->
    io.sockets.emit "data", data
    currentData = data
  actions.on "dataChunk", (dataChunk) ->
    io.sockets.emit "dataChunk", dataChunk
    if dataChunk[0] == "start"
      currentData = [dataChunk]
      currentConsole = []
    else 
      currentData.push dataChunk
  
  actions.on "errorChunk", (errorChunk) ->
    io.sockets.emit "errorChunk", errorChunk
    for d in currentData
      if d[0] == "fail" and d[1] and d[1].failure and d[1].failure == errorChunk.id
        d[1].failure = errorChunk.text.join("\n")

  actions.on "consoleChunk", (consoleChunk) ->
    io.sockets.emit "consoleChunk", consoleChunk  
    currentConsole.push consoleChunk

  parser(actions,process.stdin) 

  # starting server
  console.log "serving on port "+port
  server.listen(port)

  # args execution
  if args.opener
    opener = require "opener"
    opener("http://localhost:"+port)
  else
    io.sockets.emit "reload"
  
  # close
  close = () ->
    server.close()
    process.exit()