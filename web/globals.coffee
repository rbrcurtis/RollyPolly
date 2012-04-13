
window.log = (msg, obj) ->
	if obj
		console.log "#{msg} : #{JSON.stringify obj}"
	else
		console.log msg


window.focused = true
window.addEventListener 'focus', ->
	window.focused = true
	
window.addEventListener 'blur', ->
	window.focused = false
	

window.notify = (title, msg, icon = 'images/icons/chat.png') ->
	if not window.focused
		if window.webkitNotifications?
			n = window.webkitNotifications.createNotification(icon, title, msg)
			n.show()
			setTimeout ->
				n.cancel()
			, 3000
			
		else if window.fluid?
			log "TODO fluid notifications"
			