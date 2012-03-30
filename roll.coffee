global.util = require 'util'
roller = require './app/roller'

global.log = (msg) -> console.log msg
global.dump = (preface, obj) -> console.log "#{preface} : #{util.inspect obj}"

console.log roller.parse "1+5 2+4	2d20"
