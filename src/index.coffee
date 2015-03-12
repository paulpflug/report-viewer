"use strict"

http = require "http"
url  = require "url"
path = require "path"
events = require "events"

socketio = require "socket.io"
module.exports = (args) ->
  currentData = []
  # args processing
  port = args.port or 9999
  parser = args.parser
  throw new Error "no viewer given" if not args.viewer
  throw new Error "no files to serve" if not args.viewer.files 
  site = args.viewer

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
  io = socketio(server)
  io.on "connection", (socket) -> 
    socket.on "data", () ->
      socket.emit "data", currentData
  if site.action
    site.action.on "reload", () ->
      io.sockets.emit "reload"

  # stdin processing
  process.stdin.setEncoding("utf8")
  actions = parser(process.stdin)    
  actions.on "data", (data) ->
    io.sockets.emit "data", data
    currentData = data
  actions.on "dataChunk", (dataChunk) ->
    io.sockets.emit "dataChunk", dataChunk
    if dataChunk[0] == "start"
      currentData = [dataChunk]
    else 
      currentData.push dataChunk
  actions.on "dataConsole", (dataConsole) ->
    io.sockets.emit "dataConsole", dataConsole  


  process.stdin.on 'end', -> server.close()

  # starting server
  console.log "serving on port "+port
  server.listen(port)
  # args execution
  if args.open
    opener = require "opener"
    opener("http://localhost:"+port)
  else
    io.sockets.emit "reload"