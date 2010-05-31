class Session

	def showareas 
		print "Under Construction"
	end

	def displayuser(number)
		user = fetch_user(number)
		ldate = user.laston.strftime("%A %B %d, %Y / %I:%M%p (%Z)") 
		write "%R#%W#{number-1} %G #{user.name}"
		write "%R [DELETED]" if user.deleted 
		write "%R [LOCKED]" if user.locked
		print ""
		print <<-here
		%CLast IP:       %G#{user.ip}
		%CEmail Address: %G#{user.address}
		%CLocation:      %G#{user.citystate}
		%CLast On:       %G#{ldate}
		%CPassword:      %G********   %CLevel: %G#{user.level}
		%CRSTS Password: %G#{user.rsts_pw}
		%CRSTS Account:  %G#{RSTS_BASE},#{user.rsts_acc}
                here
		print "%YArea#:         012345678901234567890"
                 
		write "%YAccess:%W        "
		if user.areaaccess == nil then user.areaaccess = [] end
		for i in 0..20
		  if user.areaaccess[i] == nil then write "-" else write user.areaaccess[i] end
		end
		print 
		print 
		print 
	end #displayuser

	def usermenu 
	  total = u_total
	  oprompt = '"%W#{sdir}User [%p] (0-#{u_total - 1}): "'
		readmenu(
			:initval => 1,
			:range => 0..(u_total - 1),
			:prompt => oprompt
		) {|sel, upointer, moved|
			if !sel.integer?
				sel.gsub!(/[-\d+]/,"")
			end
			
			displayuser(upointer+1) if moved
			case sel
			when "/"; showuser(upointer+1)
			when "Q"; upointer = true
			when "A"; changeaccess(upointer+1)
			when "L"; changeuserlevel(upointer+1)
			when "N"; changeusername(upointer+1)
			when "AD"; changeuseremail(upointer+1)
			when "RA" ; changersts_acc(upointer+1)
			when "K"; deleteuser(upointer+1)
			when "W"; displaywho
			when "PU"; page    
			when "S"; lockuser(upointer+1)
			when "P"; changepass(upointer+1)
			when "LO"; changelocation(upointer+1)
			when "G"; leave
			when "?"; gfileout ("usermnu")
			end # of case
			p_return = [upointer,u_total - 1]
			
		}
	end

	def showuser(upointer)
		if u_total > -1 then
			displayuser(upointer)
		else 
			print
			print "%RNo Users.  Something is really fucked up!"
		end
	end

	def changeaccess(upointer)
	  user = fetch_user(upointer)
		prompt = "%WMessage Area to Change (0 - #{(a_total)})<?: list, Q: Quit>: "
		tempstr = ''
		getinp(prompt) {|inp|
			tempstr = inp.upcase
			showareas if tempstr == "?"
			((tempstr =~ /[0Q]/) or (tempstr.to_i > 0)) ? true : false
		}
		tempint2 = tempstr.to_i


		if tempstr != "Q" then
			if (0..a_total).include?(tempint2)
				prompt = "Enter new access level for area #{tempint2}: "
				tempstr2 = getinp(prompt).upcase
				if tempstr2 =~ /[NIWRMC]/
					user.areaaccess[tempint2] = tempstr2
					print "Area #{tempint2} access changed to #{tempstr2}"
					update_user(user,upointer)
				else
					print "%ROut of Range"
				end
			end
		end
	end

	def changeuserlevel(upointer)
	   user = fetch_user(upointer)
		prompt = "%WUser Level? (1-255): "
		if upointer != 0 then
			tempint = getnum(prompt,1,255)
			if !tempint.nil? then
			  user.level = tempint
  			update_user(user,upointer)
			else
			  print "%RCancelled."
			  return
			 end
		else
			print "%RYou cannot change the access of the SYSOP"
		end
	end
	
	def changersts_acc(upointer)
	  user = fetch_user(upointer)
	 prompt = "%WRSTS Account? (1-254): "
	 
	   user.rsts_acc = getnum(prompt,0,254)
	   puts user.rsts_acc
	   update_user(user,upointer)
	end

	def changeusername(upointer)
	  user = fetch_user(upointer)
		prompt = "%WUser Name?: "
		if upointer != 0 then
			user.name = getinp(prompt).slice(0..24)
			update_user(user,upointer)
		else 
			print "%RYou cannot change the name of the SYSOP" 
		end
	end
	
	def changelocation(upointer)
	  user = fetch_user(upointer)
		prompt = "%WLocation?: "

			user.citystate = getinp(prompt).slice(0..40)
			update_user(user,upointer)

	end

	def changeuseremail(upointer)
	  user = fetch_user(upointer)
		prompt = "%WEnter new email address: "
		address = getinp(prompt)
		user.address = address
		update_user(user,upointer)
		print
	end



	def deleteuser(upointer)
	  user = fetch_user(upointer)
		if upointer > 0 then
			if users.deleted then
				users.deleted = false
				print "%GUser ##{upointer} UNdeleted"
			else 
				users.deleted = true
				print "%RUser ##{upointer} deleted."
			end
			update_user(user,upointer)
		else
			print "%RYou cannot delete the SYSOP." 
		end
	end

	def lockuser(upointer)
	  user = fetch_user(upointer)
		if user.locked then
			users.locked = false
			print "%GUser ##{upointer} UNlocked"
		else 
			users.locked = true
			print "%RUser ##{upointer} locked."
		end
		update_user(user,upointer)
	end

	def changepass(upointer)
	  user = fetch_user(upointer)
		pswd = getpwd("%WEnter new password: ").strip.upcase 
		pswd2 = getpwd("Enter again to confirm: ").strip.upcase 
		if pswd == pswd2
			print "Password Changed."
			user.password = pswd2
			update_user(user,upointer)
		else 
			print "%RPasswords don't match.  Try again." 
		end
	end

end #class Session

