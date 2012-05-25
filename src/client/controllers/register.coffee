Controller = require 'controllers/framework'

module.exports = class RegisterController extends Controller
	
	url: '/register'

	activate: ->
		
		@body.append @view = $((require 'views/register')())
		
		@form = $('#registerForm')
		@email    = $('#email')
		@username = $('#username')
		@password = $('#password')

		@form.on 'submit', =>
			username = @username.val()
			email    = @email.val()
			pass     = @password.val()
			
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
	
	onSuccess: (response) ->
		route 'chat'
		
	onError: (response) ->
		log 'error', response
		alert 'there was an error'
		
	onComplete: (response) ->
