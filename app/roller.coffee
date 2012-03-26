
class Roller
	
	p1: /(([0-9])+d([0-9]+)([+-\\\\*/][0-9.]+)*[+-/\\\\*]*)+/
	p2: /([0-9]+[d+-/\\\\*]?)*/
	p3: /.*[0-9]+[d+-/\\\\*][0-9]+.*/
	
	parse: (str) ->
		ret = ""
		rolls = []
		for s in str.split /\s+/
			if f = s.match(@p1) or s.match(@p2) or s.match(@p3)
				log 'matches' 
				s = @rollDice s
			ret += s+' '
			
		return ret
		
	roll: (c, d, rolls) ->
		log "roll #{c}d#{d}"
		count = +c
		die = +d
		total = 0.0
		# log(count+"d"+die)
		for x in [0...count]
			roll = Math.floor Math.random()*die+1
			rolls.push roll
			total += roll
		# log "rolled #{total} with #{rolls}"
		return total

	rollDice: (s) ->
		msg = ""
		numbers = s.split /[^0-9.]/
		ops = s.split /[0-9.]+/
		# log numbers
		# log ops
		rolls = []
		total = 0

		i = 0
		j = 1 #split always makes ops[0]==""
		while i<numbers.length and j<ops.length

			op = ops[j]
			if op is ""
				j++
				continue

			if j is 1 and op isnt "d" then total += +numbers[i++]

			if op is "d" 
				# log "d"
				number = @roll numbers[i], numbers[++i], rolls
				total+=number
				msg+=rolls.toString().replace ","
				
			else if op is "+" 
				if ops.length> j+1 and ops[j+1] is "d" 
					number = @roll numbers[i], numbers[++i], rolls 
					total += number
					j++
				else
					number = +numbers[i]
					rolls.push number
					#							log "+"+number
					total += number
					
				msg+="+"+number
				
			else if op is "-" 
				if ops.length> j+1 and ops[j+1] is "d" 
					total -= @roll numbers[i], numbers[++i], rolls
					j++
				else 
					number = +numbers[i] 
					rolls.push number
					#							log "+"+number 
					total-=number
				
			else if op is "/" 
				if ops.length> j+1 and ops[j+1] is "d" 
					total /= @roll numbers[i], numbers[++i], rolls 
					j++
				else 
					number = +numbers[i] 
					rolls.push number
					#							log "+"+number 
					total/=number
				
			if op is "*"
				log "multiply"
				if ops.length > j+1 and ops[j+1] is "d" 
					total *= @roll numbers[i], numbers[++i], rolls 
					j++
				else
					number = +numbers[i] 
					rolls.push number
					#							log "+"+number 
					total*=number
				
			
			# log "subtotal:"+total 
			j++
			i++
		
		t = Math.floor total
		
		msg = "#{s} [#{msg} = #{t}]" 
		return msg


module.exports = new Roller