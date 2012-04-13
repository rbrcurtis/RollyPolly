module.exports = 
	
	parse: (s) ->
		
		ret = ""
		
		for str in s.split /\s+/
		
			o = str
			
			p1 = /(([0-9])+d([0-9]+)([+-\\\\*/][0-9.]+)*[+-/\\\\*]*)+/
			# p2 = /([0-9]+[d+-/\\\\*]?)+/
			p3 = /[0-9]+[d+-/\\\\*][0-9]+/
			
			if str.match(p1) or str.match(p3)
				
				log "matched"
				
				rolls = []
				
				roll = (str, c, d) ->
					rolled = true
					log "roll #{c}d#{d}"
					count = +c
					die = +d
					# log(count+"d"+die)
					for x in [0...count]
						roll = Math.floor Math.random()*die+1
						rolls.push roll
					return "("+(rolls.toString().replace /,/g,"+")+")"
		
				str = str.replace /\(?([0-9]+)d([0-9]+)\)?/g, roll
				
				# 1+(5d6) [1+(4+1+5+2+3 = 15) = 16]
				str = "#{o} [#{str} = #{eval str}]"

			ret+=str+" "
				
		return ret


