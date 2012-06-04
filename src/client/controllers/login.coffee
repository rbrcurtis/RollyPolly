Controller = require 'controllers/framework'

module.exports = class LoginController extends Controller

	url: '/login'

	activate: ->
		super
		@body.append @view = $((require 'views/login')())
		
		@form = $('#loginForm')
		@username = $('#username')
		@password = $('#password')
		@register = $('#register')

		@register.on 'click', ->route 'register'

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
		alert response.responseText
		
	onComplete: (response) =>
		
			

	