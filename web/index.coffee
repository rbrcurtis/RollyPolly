
window.log = (msg) ->
	console.log msg

class RollyPollyClient
	
	constructor: ->
		@body = $('body')
		
		
	run: ->
		@wrapper               = $('<div id="chatWrapper" />')
		@wrapper.append @header = $('<div id="chatHeader" />')
		@wrapper.append @panel  = $('<div id="chatPanel" />')
		@wrapper.append @input  = $('<textarea id="chatInput" />')
		

		@body.append @wrapper
		
		@socket = io.connect document.location.href
		@socket.on 'chat', @_onChat
		
		@input.keyup (e) =>
			if e.keyCode is 13
				@socket.emit 'chat', e.target.value
				e.target.value = ''

	_onChat: (msg) =>
		@panel.append "<div class='chatMessage'>#{msg}</div>"
		
		
		

module.exports = new RollyPollyClient