global.util = require 'util'
roller = require './app/roller'

global.log = (msg) -> console.log msg
global.dump = (preface, obj) -> console.log "#{preface} : #{util.inspect obj}"

console.log roller.parse "1+5d6"
