#!/usr/bin/env ./node_modules/coffee-script/bin/coffee

sys         = require 'util'
proc        = require 'child_process'
colors      = require 'colors'
_           = require 'underscore'
fs          = require 'fs'
global.util = require 'util'

global.CONFIG = require './config'

global.notify = (title, msg, error = false) ->
	if error and msg is 'The "sys" module is now called "util". It should have a similar interface.'
		return

	proc.spawn 'growlnotify', ["-m", msg, title]
	if error
		console.log "#{title} : #{msg}".red
	else
		console.log "#{title} : #{msg}".green

global.log = (msg, obj, depth = 2) ->
	if obj
		console.log "#{new Date()} #{msg} : #{util.inspect obj, null, depth}"
	else
		console.log "#{new Date()} #{msg}"

if process.env.PROC_MASTER

	port = process.env.port or 8080

	app = require './src/server'
	app.run(__dirname, port)

else
	appPath = "#{__dirname}/src/server"
	process.env.NODE_PATH+=":#{appPath}"

	startMaster = ->
		process.env.PROC_MASTER = true
		if process.argv[2] then process.env.port = process.argv[2]

		master = proc.spawn __filename, [], process.env
		master.stdout.on 'data', (buffer) -> console.log buffer.toString().trim() 
		master.stderr.on 'data', (buffer) -> notify "ERROR", buffer.toString().trim(), true

		return master

	master = startMaster()

	onChange = (file) =>
		notify "Restarting", "#{file.substr file.lastIndexOf('/')+1} changed"
		master.kill()
		master = startMaster()

	watchDir = (dir) ->
		fs.readdir dir, (err, files) =>
			if err?
				notify "error", err, true
				return
			for file in files
				file = dir+"/"+file
				do (file) =>
					fs.stat file, (err, stats) =>
						throw err if err?
						if stats.isDirectory()
							watchDir file
						else
							fs.watchFile file, {interval: 500, persistent: true}, (cur, prev) =>
								if cur and +cur.mtime isnt +prev.mtime
									onChange(file)

	watchDir appPath
