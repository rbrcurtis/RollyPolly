require 'globals'


module.exports = new class RollyPollyClient
	
	constructor: ->
		@window = $(window)
		@body   = $('body')
			
		
	run: ->
		
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
