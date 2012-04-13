


module.exports = class Controller
	
	constructor: ->
		log "controller"
		@content = $('#content')
	
	activate: ->
		log 'Controller.activate', Controller.active 
		window.active?.deactivate()
		window.active = @

	deactivate: ->