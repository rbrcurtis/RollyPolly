
window.log = (msg) ->
	console.log msg

module.exports = new class RollyPollyClient
	
	constructor: ->
		@body = $('body')
		
		
	run: ->
		@window                 = $(window)
		@wrapper                = $('<div id="chatWrapper" />')
		@wrapper.append @header = $('<div id="chatHeader" />')
		@wrapper.append @panel  = $('<div id="chatPanel" />')
		@wrapper.append @input  = $('<textarea id="chatInput" />')
		

		@body.append @wrapper
		
		@_resize()
		
		@window.resize @_resize
		
		@socket = io.connect document.location.href
		@socket.on 'chat', @_onChat
		@socket.on 'login', @_login
		@socket.on 'join', @_join
		@socket.on 'part', @_part
		
		@input.keyup (e) =>
			if e.keyCode is 13
				@socket.emit 'chat', e.target.value
				e.target.value = ''

	_onChat: (hash, msg) =>
		user = $("##{hash}").attr('title')
		@panel.append "<div class='chatMessage'><img src='http://unicornify.appspot.com/avatar/#{hash}?s=20'width='25' height='25' title='#{user}'/>#{msg}</div>"
			
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
		if $("##{hash}").length>0 then return
		@header.append("<img id='#{hash}' src='http://unicornify.appspot.com/avatar/#{hash}?s=40' title='#{user}'/>")
		@_onChat hash, "<i>joined</i>"
		
	_part: (user, hash) =>
		@_onChat hash, "<i>disconnected</i>"
		$("##{hash}").remove()
		
	_resize: =>	
		@panel.css 'height', (@wrapper.height()-@header.height()-@input.height()-2)+"px"
		

module.exports = new RollyPollyClient