express = require("express")
http = require("http")
app = express()

connections = []

app.configure ->
  app.use express.static(__dirname)

server = http.createServer(app)
io = require("socket.io").listen(server)

# Set log level to 1 (warn)
io.set "log level", 1

# Listen for connection
io.sockets.on "connection", (socket) ->
  # Handle connection
  socketConnect socket
  # Add listeners
  socket.on "ondeviceorientation", socketOrientationUpdate(socket)
  socket.on "changeDown", socketChangeDown(socket)
  socket.on "changeUp", socketChangeUp(socket)
  socket.on "disconnect", socketDisconect(socket)
  socket.on "mobileConnectWithCode", mobileConnectWithCode(socket)

mobileConnectWithCode = (socket) ->
  (data) ->
    if connections[data]?
      console.log('p2p successfull')
      socket.set('peerID', data)
      socket.emit("serverAcceptedConnection", 200)
      connections[data].emit('mobileDevicePing', data)
    else
      console.log 'socket does not exist'

socketConnect = (socket) ->
  id = Math.floor(Math.random()*90000) + 10000;
  connections[id] = socket
  socket.set 'connectionID', id
  socket.emit 'connectionID', id

  console.log "Server: New connection - " + socket.id + " - " + id

socketOrientationUpdate = (socket) ->
  (data) ->
    socket.get 'peerID', (err, peerID) ->
      if connections[peerID]
        connections[peerID].emit "receiveOrientation", data
      else
        console.log 'someone broke the connection'
        
socketChangeDown = (socket) ->
  (data) ->
    console.log 'down'
    socket.broadcast.emit "changeDown", data

socketChangeUp = (socket) ->
  (data) ->
    console.log 'up'
    socket.broadcast.emit "changeUp", data

socketDisconect = (socket) ->
  ->
    console.log "Server: End Connection - " + socket.id
    socket.get 'connectionID', (err,data) ->
      connections[data] = null


server.listen 1337