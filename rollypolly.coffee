#!/usr/bin/env ./node_modules/coffee-script/bin/coffee

sys     = require 'util'
proc    = require 'child_process'
colors  = require 'colors'
_       = require 'underscore'
fs      = require 'fs'
global.util = require 'util'

global.notify = (title, msg, error = false) ->
	if error and msg is 'The "sys" module is now called "util". It should have a similar interface.'
		return

	proc.spawn 'growlnotify', ["-m", msg, title]
	if error
		console.log "#{title} : #{msg}".red
	else
		console.log "#{title} : #{msg}".green

global.log = (msg, obj, depth = 0) ->
	if obj
		console.log "#{msg} : #{util.inspect obj, null, depth}"
	else
		console.log "#{msg}"

if process.env.PROC_MASTER

	app = require './app'
	app.run(__dirname)

else
	appPath = "#{__dirname}/app"
	process.env.NODE_PATH+=":#{appPath}"
	startMaster = ->
		master = proc.spawn __filename, [], _.extend process.env, {PROC_MASTER:true}
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
