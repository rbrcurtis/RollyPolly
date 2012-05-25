Controller = require 'controllers/framework'

module.exports = class LoginController extends Controller

	url: '/login'

	activate: ->
		super
		@body.append require 'views/login'
		
		@view = $('#loginWrapper')
		@form = $('#loginForm')
		@username = $('#username')
		@password = $('#password')
		@register = $('#register')

		@form.on 'submit', =>
			
			log 'ze login'
			
			try
			
				options = 
					url:      @url
					type:     'post'
					data:     @form.serialize()
					success:  @onSuccess
					error:    @onError
					complete: @onComplete
					
				$.ajax options
			
			catch e
				console.error e
			
			return false
			
	deactivate: ->
		@view.remove()
	
	onSuccess: (response) =>
		route 'chat'
		
	onError: (response) =>
		log 'error', response
		alert 'there was an error'
		
	onComplete: (response) =>
		
			
		@register.on 'click', ->route 'register'

	