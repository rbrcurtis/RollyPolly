require 'globals'


module.exports = new class RollyPollyClient
	
	constructor: ->
		@window = $(window)
		@body   = $('body')
			
		
	run: ->
		# @_resize()
		# @window.resize @_resize
		
		@body.html require 'views/main'
		
		@header = $('#header')
		@footer = $('#footer')
		
		@header.html require 'views/header'

		@settings = $('#settings')
		@settings.click (e) =>
			 if window.webkitNotifications?
				 window.webkitNotifications.requestPermission ->
				 	notify 'foo', 'bar'
			 else
			 	alert 'this setting only works in chrome'
		

		require 'router'

	# _resize: =>	
		# @body.css 'height', (@window.height())+"px"