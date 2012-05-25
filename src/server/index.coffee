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
async		= require 'async'

roller		= require 'roller'
repo		= require 'repo'

module.exports = new class App
	
	users: {}
	
	run: (path, port) ->
		
		# setInterval(
			# =>
				# log 'users', @users
			# 15000
		# )
		
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
			src = "#{path}/style"
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
		repo.createUser req.body.email, req.body.username, req.body.password, (err, user) =>
			if err then return res.send err.toString()
			
			res.cookie CONFIG.cookies.auth.name, user.token,
				expires: new Date(Date.now() + CONFIG.cookies.auth.lifetime)
				httpOnly: true
				domain: CONFIG.cookies.auth.domain
			res.send("registered!")
		
		
	_login: (req, res) =>
		log 'login', req.body
		repo.authUser req.body.username, req.body.password, (err, user) =>
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
			log "authentication exception", ex
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
			
	serializeUser: (user) ->
		return {username:user.username, display: user.display, hash: @_hash user.email}
		
	_onDisconnect: (socket) ->
		log "#{socket.user.username} disconnecting"
		if not @users[socket.user._id] or @users[socket.user._id]?._idleTimeout
			return log 'already disced'
			
		user = socket.user
		
		@users[user._id] = setTimeout(
			=>
				if not @users[user._id]?._idleTimeout?
					return log 'cancelling disc'
				repo.saveChatMsg user._id, "<i>disconnected</i>"
				@io.sockets.emit 'part', @serializeUser(user)
				delete @users[user._id]
			15000
		)	
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
			@io.sockets.emit 'chat', @serializeUser(socket.user), msg
			repo.saveChatMsg socket.user._id, msg

	_onNick: (socket, nick) ->
		log "#{socket.user.display} changing display name to '#{nick}'"
		
		socket.user.display = nick
		repo.updateDisplayName user
		@io.sockets.emit 'nick', @serializeUser(socket.user)
		
	_onLogin: (socket) ->
		log 'login', socket.user.username
		
		#tell this dude everyone else that is online
		log 'socket length', Object.keys(@io.sockets.sockets).length
		for id,s of @io.sockets.sockets
			log 'socket', s.user.username
			socket.emit 'join', @serializeUser(s.user)
		
		#tell everyone else this dude is online
		@io.sockets.emit 'join', @serializeUser(socket.user)
		
		repo.getHistory (err, history) =>
			users = {}
			log "history", {err, length:history.length}
			async.forEachSeries(
				history
				(msg, callback) =>
					convert = (msg, user) =>
						delete msg.userId
						msg.user = @serializeUser(user)
						
					if users[msg.userId]
						convert msg, users[msg.userId]
						callback null
						
					else repo.getUserById msg.userId, (err,userArr) =>
						user = userArr[0]
						if err then return callback err
						users[msg.userId] = user
						convert msg, user
						callback null
					
				(err) =>
					socket.emit 'history', history
					if @users[socket.user._id]?
						if @users[socket.user._id]._idleTimeout?
							log "clearing recent disc"
							@users[socket.user._id] = socket.user
						else log "this dude has not disconnected"
					else
						@users[socket.user._id] = socket.user
						@io.sockets.emit 'chat', @serializeUser(socket.user), "<i>joined</i>"
						repo.saveChatMsg socket.user._id, "<i>joined</i>"
			)

