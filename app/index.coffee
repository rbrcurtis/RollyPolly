express = require 'express'
stitch  = require 'stitch'
stylus  = require 'stylus'
sio     = require 'socket.io'
roller  = require 'roller'
crypto  = require('crypto')

class App
	
	run: (path, port) ->
		
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
		
		server.listen port, ->
			addr = server.address()
			console.log "listening on #{addr.address}:#{addr.port}"
			
	_hash: (nick) ->
		crypto.createHash('md5').update(nick).digest("hex");
			
	onConnection: ->
		@io.sockets.on 'connection', (socket) =>
			log "connect!"
			socket.on 'chat', => @_onChat socket, arguments...
			socket.on 'login', => @_onLogin socket, arguments...
			socket.on 'disconnect', => @_onDisconnect socket
			socket.emit 'login'
		
	_onDisconnect: (socket) ->
		log "#{socket.nick} disconnected"
		@io.sockets.emit 'part', socket.nick, socket.hash
			
	_onChat: (socket, msg) ->
		msg = msg.trim()
		if msg is '' then return
		log "got msg '#{msg}'"
		if m = msg.match /\/nick ?(.*)/
			if m[1]?
				@_onLogin socket, m[1]
			else
				socket.emit 'login', true
		else
			msg = roller.parse msg
			@io.sockets.emit 'chat', socket.hash, msg
		
	_onLogin: (socket, nick) ->
		if socket.nick?
			log "#{socket.nick} changing nick to #{nick}"
			@io.sockets.emit 'part', socket.nick, socket.hash
		socket.nick = nick
		socket.hash = @_hash nick
		log "socket #{socket.id} set nick to #{socket.nick}:#{socket.hash}"
		@io.sockets.emit 'join', socket.nick, socket.hash
		for id,s of @io.sockets.sockets
			socket.emit('join', s.nick, s.hash) unless s.nick is nick
		

module.exports = new App