roller = require './app/roller'
global.log = (msg) -> console.log msg
console.log roller.parse "3d20+4"
