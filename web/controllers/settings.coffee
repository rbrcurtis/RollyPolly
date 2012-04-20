Controller = require 'controllers/framework'

module.exports = class Settings extends Controller
	
	activate: ->
		super
		
		@content.html require 'views/jaja'
		
		