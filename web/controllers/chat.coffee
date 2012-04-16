Controller = require 'controllers/framework'

module.exports = class ChatController extends Controller
	
	constructor: ->
		super
		@window  = $(window)
		
		
	activate: ->
		super
		
		@content.html require 'views/chat'
		
		@wrapper = $('#chatTable')
		@header  = $('#chatHeader')
		@panel   = $('#chatPanel')
		@input   = $('#chatInput')
		
		@socket = io.connect document.location.href
		
		@socket.on 'connect', =>
			log "connected"
			@panel.html ''
		@socket.on 'chat', @_onChat
		@socket.on 'login', @_login
		@socket.on 'join', @_join
		@socket.on 'nick', @_nick
		@socket.on 'part', @_part
		@socket.on 'history', @_history
		
		@input.keyup (e) =>
			if e.keyCode is 13
				@socket.emit 'chat', e.target.value
				e.target.value = ''

	deactivate: ->
		super
		log "wonder twin powers deactivate!"
		@socket.disconnect()
		
		
	_onChat: (hash, msg) =>
		user = $("##{hash}").attr('title')
		@panel.append "<div class='chatMessage'><img src='http://unicornify.appspot.com/avatar/#{hash}?s=20'width='25' height='25' title='#{user}'/>#{msg}</div>"
		@panel.scrollTop @panel[0].scrollHeight
		notify user, msg, "http://unicornify.appspot.com/avatar/#{hash}?s=20"
			
	getNickFromCookie: ->
		if not document.cookie then return null
		cs = document.cookie.split ';'
		for c in cs
			[key,val] = c.split('=')
			if key.trim() is 'nick' then return val
			
		return null
			
	_login: (clear=false) =>
		if not clear then nick = @getNickFromCookie()
		while not nick?
			nick = prompt "Please enter a nickname.  This can be changed with /nick"
		@socket.emit 'login', nick
		document.cookie = "nick=#{nick}"
		
	_join: (user,hash) =>
		log 'join', {user,hash}
		if $("##{hash}").length>0 then return
		@header.append "<img id='#{hash}' src='http://unicornify.appspot.com/avatar/#{hash}?s=40' title='#{user}'/>"
		
	_nick: (oldUser, oldHash, user, hash) =>
		@header.append "<img id='#{hash}' src='http://unicornify.appspot.com/avatar/#{hash}?s=40' title='#{user}'/>"
		@_onChat oldHash, "<i>is now a pretty unicorn known as <img src='http://unicornify.appspot.com/avatar/#{hash}?s=20'width='25' height='25' title='#{user}'/></i>"
		$("##{oldHash}").remove()
		
	_part: (user, hash) =>
		@_onChat hash, "<i>disconnected</i>"
		$("##{hash}").remove()
		
	_history: (msgs) =>
		for msg in msgs
			@_onChat msg.hash, msg.msg
		

