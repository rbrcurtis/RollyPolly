Controller = require 'controllers/framework'

module.exports = class ChatController extends Controller
	
	users: {}
	
	constructor: ->
		super
		@window  = $(window)
		@body    = $('body')
		
		
	activate: ->
		super
		
		log 'chat activating', @
		
		@content.html require 'views/chat'
		
		@wrapper = $('#chatTable')
		@header  = $('#chatHeader')
		@panel   = $('#chatPanel')
		@input   = $('#chatInput')
		
		unless @socket
			window.socket = @socket = io.connect document.location.href
		else
			@socket.socket.reconnect()
	
		@socket.on 'error', (e) =>
			log "error connecting to socket: #{e}"
			if e is 'handshake unauthorized'
				route 'login'
		
		@socket.on 'connect', =>
			log "connected"
			@panel.html ''
		@socket.on 'chat', @_onChat
		@socket.on 'welcome', @_welcome
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
		log "chat deactivate!"
		@socket.disconnect()
		
	avatar: (hash, s=20) ->
		return "http://www.gravatar.com/avatar/#{hash}?d=monsterid&s=#{s}"
		
		
	_onChat: (user, msg) =>
		@panel.append "<div class='chatMessage'><img src='#{@avatar user.hash, 20}' width='25' height='25' title='#{user.display}'/>#{msg}</div>"
		@panel.scrollTop @panel[0].scrollHeight
		notify user.display, msg, @avatar(user.hash, 20)
			
	_welcome: (@me) =>
		log 'welcome', @me
		@_join @me
	
	
	_join: (user) =>
		log 'join', user.display, user.hash
		if $("##{user.hash}").length>0 then return
		@header.append "<img id='#{user.hash}' src='#{@avatar user.hash, 40}' title='#{user.display}'/>"
		
	_nick: (user, nick) =>
		u = $("##{user.hash}")
		if not u.length
			log 'nick notice for unknown user', nick
			return
		u.attr 'title', nick
		@_onChat user, "<i>is now known as #{nick}</i>"
		
	_part: (user, hash) =>
		@_onChat user, "<i>disconnected</i>"
		$("##{user.hash}").remove()
		
	_history: (msgs) =>
		for msg in msgs
			@_onChat msg.user, msg.msg
		

