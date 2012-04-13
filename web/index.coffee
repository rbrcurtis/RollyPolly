require 'globals'
Chat = require 'controllers/chat'
Settings = require 'controllers/settings'



module.exports = new class RollyPollyClient
	
	constructor: ->
		@window = $(window)
		@body   = $('body')
			
		
	run: ->
		@_resize()
		@window.resize @_resize
		
		@body.html require 'views/main'

		@chatScreen = new Chat
		@settingsScreen = new Settings

		@settings = $('#settings')
		@settings.click (e) =>
			 if window.webkitNotifications?
				 window.webkitNotifications.requestPermission ->
				 	notify 'foo', 'bar'
			 else
			 	alert 'this setting only works in chrome'
		
		
		@chatScreen.activate()


	_resize: =>	
		@body.css 'height', (@window.height())+"px"