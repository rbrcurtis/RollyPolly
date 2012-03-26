express = require 'express'
stitch  = require 'stitch'
stylus  = require 'stylus'
sio     = require 'socket.io'
roller  = require 'roller'

class App
	
	run: (path) ->
		
		BUNDLE = '/bundle.js'

		bundle = stitch.createPackage paths: [path + '/web']
		
		server = express.createServer()
		
		@io = sio.listen server
		@io.set 'log level', 0
		
		@onConnection()
		
		server.get BUNDLE, bundle.createServer()
		
		server.use stylus.middleware
			src:  path + '/style'
			dest: path + '/public'
			force: true
		
		server.use express.static(path + '/public')
		
		server.listen 8080, ->
			addr = server.address()
			console.log "listening on #{addr.address}:#{addr.port}"
			
	onConnection: ->
		@io.sockets.on 'connection', (socket) =>
			socket.on 'chat', @_onChat
			
	_onChat: (msg) =>
		msg = roller.parse msg
		@io.sockets.emit 'chat', msg

module.exports = new App