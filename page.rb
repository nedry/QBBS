class Session
	def page
		to = getinp("%GUser to Page: ",false).strip
		return if to == ""
		if @who.user(to).nil? then
			print "%R-Sorry, that user is not online..."
			print " "
			return
		end
		message = getinp("%CMessage: ",false).strip
		return if message == "" 
		#print to
		@who.user(to).page ||= Array.new #yet another linux nil check
		@who.user(to).page.push("%CPAGE (%Gfrom #{@c_user.name} in %M#{@who.user(@c_user.name).where}%C): #{message}")
		print "%GMessage Sent."
	end
end
