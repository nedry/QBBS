class Session
	def page
		to = getinp("%GUser to Page: ")
                exists = get_uid(to)
                if exists.nil? then
                  print "%RThat user does not exist."
                  print
                  return
                end
		return if to == ""
		if @who.user(to).nil? and  !who_exists(exists) then
			print "%R#{to} is not online... %Gthey will get the message when they log in."
			print 
		end
		message = getinp("%CMessage: ")
		return if message == "" 
                add_page(@c_user.number,to,message,false)
		print "%GMessage Sent."
	end
end
