Controller = require 'controllers/framework'

module.exports = class RegisterController extends Controller
	

	activate: ->
		@body.html require 'views/register'
		
		@wrapper = $('#loginWrapper')
		@form = $('#registerForm')
		@email    = $('#email')
		@username = $('#username')
		@password = $('#password')

		@form.on 'submit', =>
			log 'submit!'
			return false
			
