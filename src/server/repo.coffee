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
		# if not doc._id
			# cb "_id not set" if cb?
			# return
			
		@_onReady =>
			Repo.db.collection collection, (err, col) =>
				return cb err if err?
				col.update {_id:doc._id}, doc, {upsert:true}, (err, docs) =>
					return cb err if err?
					cb(null) if cb?
					
	
	_find: (collection, query, cb) ->
		log "_find: (#{collection}, #{JSON.stringify query}, #{cb?}) ->"
		@_onReady =>
			Repo.db.collection collection, (err, col) =>
				return cb err, null if err?
				col.find query, (err, cursor) =>
					return cb err, null if err?
					cursor.toArray (err,docs) =>
						return cb err, null if err?
						cb null, docs
						
						
						
	saveChatMsg: (user, hash, msg) ->
		log "save chat #{user}:#{hash}:#{msg}"
		@_insert 'messages', {user,hash,msg,time:new Date().getTime()}, (err) ->
			if err? then log err 
			
	getHistory: (cb) ->
		@_find 'chat', {time:{$gt:new Date().getTime()-1000*60*60*24}}, cb
		
	getUserByToken: (token, callback) ->
		@_find 'users', {token}, callback
		
	createUser: (email, username, password, callback) ->
		[salt, securePass] = @hashPassword password
		@_insert 'users', {email, username, salt, password:securePass, token:randomText()}
		
	authUser: (email, password, callback) ->
		unless callback then return
		@_find 'users', {email}, (err, user) =>
			if err
				log 'user lookup err', err
				return callback false
			else if user.length is 0
				log 'user not found', email
				return callback false
			else if user.length > 1 
				log 'too many users found', email
				return callback false
			else user = user[0]
			
			securePass = @hash password, user.salt
			log 'securepass', securePass
			callback securePass is user.password
			 
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
		
		
			
		salt = generateSalt()
		securePass = @hash password, salt
		
		return [salt, securePass]
