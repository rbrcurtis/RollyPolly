express = require 'express'
stitch  = require 'stitch'
stylus  = require 'stylus'
sio     = require 'socket.io'
roller  = require 'roller'
crypto  = require 'crypto'
repo    = require 'repo'

class App
	
	run: (path, port) ->
		
		BUNDLE = '/bundle.js'

		bundle = stitch.createPackage paths: [path + '/web']
		
		server = express.createServer()
		
		@io = sio.listen server
		@io.set 'log level', 0
		@io.set 'transports', ['xhr-polling']
		
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
			log "connect!", socket.id
			socket.on 'chat', => @_onChat socket, arguments...
			socket.on 'login', => @_onLogin socket, arguments...
			socket.on 'disconnect', => @_onDisconnect socket
			socket.emit 'login'
		
	_onDisconnect: (socket) ->
		log "#{socket.nick} disconnected"
		
		if s.nick is nick and id isnt socket.id
			if s.nick is nick
				log "duplicate"
				return
			
			
		repo.saveChatMsg socket.nick, socket.hash, "<i>disconnected</i>"
		@io.sockets.emit 'part', socket.nick, socket.hash
			
	_onChat: (socket, msg) ->
		msg = msg.trim()
		if msg is '' then return
		log "got msg '#{msg}'"
		if m = msg.match /\/nick ?(.*)/
			if m[1].length
				@_onNick socket, m[1]
			else
				socket.emit 'login', true
		else
			msg = roller.parse msg
			@io.sockets.emit 'chat', socket.hash, msg
			repo.saveChatMsg socket.nick, socket.hash, msg

	_onNick: (socket,nick) ->
		log "#{socket.nick} changing nick to '#{nick}'"
		if not socket.nick? then return @_onLogin socket, nick
		
		hash = @_hash nick

		@io.sockets.emit 'nick', socket.nick, socket.hash, nick, hash
		repo.saveChatMsg socket.nick, socket.hash "<i>is now a pretty unicorn known as <img src='http://unicornify.appspot.com/avatar/#{hash}?s=20'width='25' height='25' title='#{nick}'/></i>"
		socket.nick = nick
		socket.hash = hash
		
			
	_onLogin: (socket, nick) ->
		if socket.nick? then return @_onNick socket, nick
		
		socket.nick = nick
		socket.hash = @_hash nick

		log "socket #{socket.id} logged in as #{socket.nick}:#{socket.hash}"
			
		
		for id,s of @io.sockets.sockets
			if s.nick is nick and id isnt socket.id
				log 'duplicate'
				return
		
		for id,s of @io.sockets.sockets
			socket.emit('join', socket.nick, socket.hash)
		
		repo.getHistory (err, history) =>
			log "history #{history.length}"
			socket.emit 'history', history
			@io.sockets.emit 'chat', socket.hash, "<i>joined</i>"
			repo.saveChatMsg socket.nick, socket.hash, "<i>joined</i>"
		

module.exports = new App