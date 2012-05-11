fs 			= require 'fs'
pathy		= require 'path'

express 	= require 'express'
connect 	= require 'connect'
stitch		= require 'stitch'
stylus		= require 'stylus'
nib			= require 'nib'
sio			= require 'socket.io'
crypto		= require 'crypto'
jade		= require 'jade'

roller		= require 'roller'
repo		= require 'repo'

module.exports = new class App
	
	run: (path, port) ->
		
		BUNDLE = '/bundle.js'
		CSSBUNDLE = '/bundle.css'

		bundle = stitch.createPackage
			paths: [path + '/src/client']
			compilers:
				jade: (module, filename) ->
					source = require('fs').readFileSync(filename, 'utf8')
					source = "module.exports = " + jade.compile(source, {compileDebug : false, client: true}) + ";"
					module._compile(source, filename)
					
		bundleStylus = (req, res) ->
			src = "#{process.env.PWD}/style"
			log 'styles', src
		
			fs.readdir src, (err, files) ->
				console.log "stylus bundle: cannot read directory #{src} because #{err}" if err
				result = "@import 'nib'\n"
				result += "@import '#{file}'\n" for file in files when pathy.extname(file) is '.styl'
		
		
				stylus(result)
					.set('paths', [src])
					.use(nib())
					.render (err,css) ->
						console.log "stylus bundle: cannot render css because #{err}" if err
				
						res.writeHead 200, 'Content-Type': 'text/css'
						res.end css
						
		
		@server = express.createServer()
		
		@io = sio.listen @server
		@io.set 'log level', 0
		@io.set 'transports', ['xhr-polling']
		
		@io.set 'authorization', @_onAuthorization
		
		@onConnection()
		
		@server.use express.static(path + '/public')
		@server.use express.bodyParser()
		
		@server.get BUNDLE, bundle.createServer()
		@server.get CSSBUNDLE, bundleStylus
		
		@server.post '/register', @_register
		@server.post '/login', @_login

		@server.listen port, =>
			addr = @server.address()
			console.log "listening on #{addr.address}:#{addr.port}"
			
	_hash: (nick) ->
		crypto.createHash('md5').update(nick).digest("hex")
		
	_register: (req, res) =>
		repo.createUser req.body.email, req.body.username, req.body.password, (err, user) ->
			if err then return res.send err.toString()
			
			res.cookie CONFIG.cookies.auth.name, user.token,
				expires: new Date(Date.now() + CONFIG.cookies.auth.lifetime)
				httpOnly: true
				domain: CONFIG.cookies.auth.domain
			res.send("registered!")
		
		
	_login: (req, res) =>
		authUser: (email, password, callback) ->
		repo.authUser req.body.email, req.body.username, req.body.password, (err, user) =>
			if err then return res.send err.toString()
			
			res.cookie CONFIG.cookies.auth.name, user.token,
				expires: new Date(Date.now() + CONFIG.cookies.auth.lifetime)
				httpOnly: true
				# domain: CONFIG.cookies.auth.domain
			res.send("success!")
		
	_onAuthorization: (data, accept) =>
		
		log "auth!"
		# return accept null, true
		
		
		try
			cookies = if data.headers.cookie then connect.utils.parseCookie(data.headers.cookie) else {}
			data.token = cookies[CONFIG.cookies.auth.name]
			unless data.token?
				log "cookie not found"
				log 'cookies', cookies
				return accept(null, false)
			else
				log "found auth cookie: #{data.token}"
				
				repo.getUserByToken data.token, (err, users) =>
					if err?
						log "error finding user"
						dump err
						return accept(null, false)
					if users?.length
						log "authentication successful for user", users
						data.user = users[0]
						return accept(null, true)
					else
						log 'user not found'
						return accept(null, false)
				
		catch ex
			log "authentication exception: #{util.inspect ex}"
			return accept(null, false)
	
			
	onConnection: ->
		@io.sockets.on 'connection', (socket) =>
			socket.user = socket.handshake.user
			socket.user.socketId = socket.id
			log "connect!", {socketId:socket.id, user:socket.user.username}
			socket.on 'chat', => @_onChat socket, arguments...
			socket.on 'disconnect', => @_onDisconnect socket
			socket.on 'nick', => @_onNick socket, arguments...
			
			@_onLogin socket
			
	_serializeUser: (user) ->
		return {username:user.username, display: user.display, hash: @_hash user.email}
		
	_onDisconnect: (socket) ->
		log "#{socket.nick} disconnected"
		
		return
		
		for id,s of @io.sockets.sockets
			if socket.nick is s.nick and s.id isnt socket.id
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

	_onNick: (socket, nick) ->
		log "#{socket.user.display} changing display name to '#{nick}'"
		
		socket.user.display = nick
		repo.updateDisplayName user
		@io.sockets.emit 'nick', @_serializeUser socket.user
		
	# TODO deprecate
	_onLogin: (socket) ->
		
		for id,s of @io.sockets.sockets
			socket.emit 'join', @_serializeUser socket.user
		
		repo.getHistory (err, history) =>
			log "history #{history.length}"
			socket.emit 'history', history
			@io.sockets.emit('chat', @_serializeUser(socket.user), "<i>joined</i>")
			repo.saveChatMsg socket.user._id, "<i>joined</i>"
		

