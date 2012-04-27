
module.exports = new class Router
	
	routes:
		'chat': new (require 'controllers/chat')
		'login': new (require 'controllers/login')
		'register': new (require 'controllers/register')
		
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

