ChatController = require 'controllers/chat'
LoginController = require 'controllers/login'


module.exports = new class Router
	
	routes:
		'chat': new ChatController
		'login': new LoginController
		
	constructor: ->
		@route 'chat'
		
		window.route = @route

	route: (route) =>
		log "routing to #{route}"
		if @current
			log "previous was #{@current.constructor.name}"
		@current?.deactivate()
		@current = @routes[route]
		@current.activate()
