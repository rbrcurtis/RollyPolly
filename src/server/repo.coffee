mongo = require 'mongodb'
crypto = require 'crypto'

module.exports = new class Repo
	
	@queue = []
	@connected = false
	@db = new mongo.Db('rollypolly', new mongo.Server('localhost', 27017))
	@db.open (err, p_client) =>
		throw err if err?
		log "connected"
		cb() while cb = @queue.shift()
		@connected = true
	
	_onReady: (cb) ->
		if Repo.connected then cb()
		else Repo.queue.push cb
		
	_insert: (collection, doc, cb) ->
		@_onReady =>
			Repo.db.collection collection, (err, col) =>
				return cb err if err?
				col.update {_id:doc._id}, doc, {upsert:true}, cb
					
	
	_find: (collection, query, cb) ->
		log "_find: ", JSON.stringify {collection, query, cb:cb?}
		@_onReady =>
			Repo.db.collection collection, (err, col) =>
				return cb err, null if err?
				col.find query, (err, cursor) =>
					return cb err, null if err?
					cursor.toArray (err,docs) =>
						return cb err, null if err?
						cb null, docs
						
	updateDisplayName: (user) ->
		@_insert 'users', user
						
	saveChatMsg: (userId, msg) ->
		log "save chat", {userId, msg}, 0
		@_insert 'messages', {userId, msg, time:new Date()}, (err) ->
			if err? then log err 
			
	getHistory: (cb) ->
		d = new Date()
		d.setTime(d.getTime()-1000*60*60*24)
		@_find 'messages', {time:{$gt:d}}, cb
		
	getUserByToken: (token, callback) ->
		@_find 'users', {token}, callback

	getUserById: (_id, callback) ->
		@_find 'users', {_id}, callback
		
	createUser: (email, username, password, callback) ->
		if not callback then callback = -> {}
		if not (email and username and password) then return callback 'invalid input' 
		
		email = email.toLowerCase()
		username = username.toLowerCase()
		
		unless email.match /^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,6}$/ then return callback "invalid email address"
		unless password.length > 5 then return callback 'your password is too short'
		
		query = 
			$or: [
				{email}
				{username}
			]
				
		@_find 'users', query, (err, users) =>
			if users.length>=1
				user = users[0]
				if email is user.email then return callback "that email is already in use"
				else if username is user.username then return callback "that username is already in use"
				
			[salt, securePass] = @hashPassword password
			user = {email, username, display:username, salt, password:securePass, token:@randomText()}
			
			@_insert 'users', user, (err) =>
				if err then return callback err
				@_find 'users', {username}, (err, users) ->
					return callback null, users[0]
				
		
	authUser: (identity, password, callback) ->
		unless callback then return
		
		query = 
			$or: [
				{email:identity}
				{username:identity}
			]
			
		@_find 'users', query, (err, user) =>
			if err
				log 'user lookup err', err
				return callback err
			else if user.length is 0
				log 'user not found', email
				return callback null, null
			else if user.length > 1 
				log 'too many users found', email
				return callback 'too many users found', null
			else user = user[0]
			
			securePass = @hash password, user.salt
			log 'securepass', securePass
			if securePass is user.password
				callback null, user
			else 
				callback null, null
				
			 
	hash: (msg, key) ->
		crypto.createHmac("sha256", key).update(msg).digest "hex"
		
	randomText: ->
		text = ""
		possible = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*"
		i = 0
		
		while i < 40
			text += possible.charAt(Math.floor(Math.random() * possible.length))
			i++
		return text

	hashPassword: (password) ->
			
		salt = @randomText()
		securePass = @hash password, salt
		
		return [salt, securePass]
