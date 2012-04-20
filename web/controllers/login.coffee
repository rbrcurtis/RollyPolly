Controller = require 'controllers/framework'

module.exports = class LoginController extends Controller

	activate: ->
		super
		@body.append require 'views/login'
		
		@login = $('#loginWrapper')
		@form = $('#loginForm')
		@username = $('#username')
		@password = $('#password')

		@form.on 'submit', =>
			log 'submit!'
			return false
