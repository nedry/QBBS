class Session

	def checkpassword (username, password) 
		if @users[username] == nil
			add_log_entry(8,Time.now,"sent def checkpassword a bad username.")
			return false
		else
			return (@users[username].password == password)
		end 
	end 

	def figureip(peername)
		i = peername.unpack('snCCCCa8')
		ip = "#{i[2]}.#{i[3]}.#{i[4]}.#{i[5]}"
		return ip
	end

  def detect_ansi
   print "\e[s"			#Save Cursor Position
   print "\e[99B_"		#locate Cursor as far down as possible
   print "\e[6n"		#Get Cursor Position
   print "\e[u"			#Restore Cursor Position
   #print "\e[0m_"		#Set Normal Colours
   print "\e[;1;37;40m"
   print "\e[2J"		#Clear Screen
   print "\e[H"			#Home Cursor

   i = 0
   while i < 50
    i +=1
    test = @socket.getc if select([@socket],nil,nil,0.1) != nil
    if test == ESC.chr #fix for 1.9
     sleep(2)
     while select([@socket],nil,nil,0.1) != nil
      junk = @socket.getc
     end
     return true
    end
   end
  return false
 end
    
	def logon   
		ip= figureip(@socket.getpeername)
		print
		ddate = Time.now.strftime("%m/%d/%Y at %I:%M%p") 
		add_log_entry(6,Time.now,"IP: #{ip}.")
                if detect_ansi then
                 sleep(1)
                 print "ANSI Detected"
                 ansi = true
                else
                 print "ANSI not Detected"
                 ansi = false
                end
		spam
		print VER
		print ("IP Address detected: #{ip}")
		print ("Fidonet Node: #{FIDOZONE}:#{FIDONET}/#{FIDONODE}.#{FIDOPOINT}")
                if ansi and File.exists?(TEXTPATH + "welcome1.ans") then
                 fileout(TEXTPATH + "welcome1.ans")
                else
		 fileout(TEXTPATH + "welcome1.txt")
                end

		checkmaxsessions

		count = 0

		while true
		
			count +=1
			username = ''
			getinp("Enter your name: ",false) {|inp|
				username = inp.strip
				#print "got #{username}"
			  username != ""
			}
			#print "Username = #{username}"
			if username.split.length < 2
				userlastname = getinp("Enter your LAST name or <CR>: ",false) {|inp|
					inp == "CR" ? crerror : true
				}.strip
				username = (username + SPACE + userlastname).strip
				
			end
			happy = username.rindex(/[,*@:\']/)

			happy = 1 if (username.length < 3) or (username.length > 25)

    if happy.nil? then
			if !user_exists(username) then
				#username.upcase!
				if yes("Create new user #{username}? [Y,n]",true,false,true)
				   newuser(username, ip)
				else
					next # input name again
				end	
			end

			password = getpwd("Enter password for user #{username}: ")
			
			 break if check_password(username.upcase, password)
			 checkmaxpwdmiss(count)
			else 
			 print "User IDs must be between 3 and 25 characters, and may not contain"
			 print "the characters : * @ , ' "
			end
		end #of while...true

		checkkillfile(username)
		checkmultiplelogon
		#puts @message.class
		@message.push("*** #{@c_user.name} has just logged into the system.")

		logandgreetuser(username, ip)
		if !@c_user.fastlogon then
		 ogfileout("welcome2",4,true)
		 yes("%WPress %Y<--^%W: ",true,false,true)
		 displaywho
		end
		
	end 

	def checkmaxsessions
		toomany = @who.len
		if toomany >= NODES then
			add_log_entry(7,Time.now,"Maximum Sessions Exceeded!")
			
			fileout(TEXTPATH + "toomany.txt")
			sleep(10)
			hangup
		end
	end

	def newuser(username, ip)
		password = nil
		
		while !password
			password = getandconfirmpwd
		end
                while true
		 prompt = "Enter your Email Address:       : "
		 address = getinputlen(prompt,ECHO,6,false)
		  happy = (/^(\S*)@(\S*)\.(\S*)/) =~ address
		  if happy.nil? then 
		   print "Not a valid email address.  Please enter a valid email address."
		  else break end
		end
		prompt = "Enter your Location:            : "
		location = getinputlen(prompt,ECHO,6,false)
		prompt = "ANSI [IBM] Graphics        [Y,n]? "
		ansi = yes(prompt,true,false,true)
		prompt = "Full Screen Editor         [Y,n]? "
		fullscreen = yes(prompt,true,false,true)
		prompt = "MORE prompt                [Y,n]? "
		more =yes(prompt,true,false,true)
    add_user(username,ip,password,location,address,24,80,ansi, more, DEFLEVEL, fullscreen) 
		@c_user = fetch_user(get_uid(username))
		add_log_entry(5,Time.now,"New user #{@c_user.name} created.")
		ogfileout("newuser",2,true)
		yes("Press <--^: ",true,false,true)
	end

	def checkkillfile(username)
		@c_user = fetch_user(get_uid(username))
		if @c_user.deleted then 
		        add_log_entry(7,Time.now,"#{@c_user.name} tried to log on, but is in the kill file!")
			gfileout("killfile") 
			sleep(10)
			hangup
		end
	end

	def checkmultiplelogon
		for x in 0..(@who.len - 1)
			if @who[x].name.upcase == @c_user.name.upcase then
				add_log_entry(7,Time.now,"#{@c_user.name} multiple logon attempt.")
				gfileout("already")
				sleep(10)
				hangup
			end
		end
	end

        def add_user_to_wall
	  print "Last #{MAX_L_CALLERS} Callers."
	  print ""
	  add_wall(@c_user.number,"","Telnet")
	  wall_cull
       end
  
	def  display_wall
          i = 0
          j = 0
          cont = true
	  
         if !wall_empty  then
            cols = %w(Y G R).map {|i| "%"+i}
            headings = %w(Name Time-On Connection)
            widths = [30,20,29]
	    header = cols.zip(headings).map {|a,b| a+b}.formatrow(widths)
            underscore = cols.zip(['-'*30]*5).map{|a,b| a+b}.formatrow(widths)
	    print header
	    print underscore
            fetch_wall.each {|x|
            t= Time.parse(x.timeposted.to_s).strftime("%m/%d/%y %I:%M%p")
            temp = cols.zip([x.user.name,t,x.l_type]).map{|a,b| "#{a}#{b}"}.formatrow(widths) #fix for 1.9
	       j = j + 1
	       if j == (@c_user.length - 2) and @c_user.more then
		  cont = moreprompt
		  j = 1
	       end
	    break if !cont 
       print temp
  }
  
 else
  print "List has been cleared"
  end
 end
	def logandgreetuser(username, ip)
		add_log_entry(5,Time.now,"#{@c_user.name} logged on sucessfully.")
		@logged_on = true
		puts "-SA: Logon - #{@c_user.name}"
                node = addtowholist
		print "%WGood #{timeofday} #{username}.  You are logged into node #{node}"
		ddate = @c_user.laston.strftime("%A %B %d, %Y")
		dtime  = @c_user.laston.strftime("%I:%M%p (%Z)")
		print "%GYou were last on %B#{ddate} %C #{dtime} %W"
		if @c_user.fastlogon
		  print
		  print "%RFast User Logon Mode %YOn%R.  Skipping Logon Information."
		  print "This may be changed at the User Configuration Menu." 
		  print
		end
		if !QOTD.nil? and !@c_user.fastlogon then
		 print
		 print "Quote of the Day: " if !existfileout('qotdhdr',0,true)		 
		 door_do("#{QOTD}","")
		 existfileout('quote',0,true)
		 yes("Press %Y<--^%W: ",true,false,true)
		add_user_to_wall
		 if !@c_user.fastlogon then
		  display_wall
		  yes("Press %Y<--^%W: ",true,false,true)
		  bullets(0)
		 end
		end
		@c_user.logons = @c_user.logons.succ
		@c_user.laston = Time.now
		@c_user.ip = ip
		#@c_user.page.clear if @c_user.page != nil #yet another linux nil check
                update_user(@c_user)
	end

	def checkmaxpwdmiss(count)
		if count == MAXPASSWORDMISS then
			fileout(TEXTPATH + "missed.txt")
			add_log_entry(7,Time.now,"#{username} missed his password more than #{MAXPASSWORDMISS} times, and was disconnected.")
			sleep(10)
			hangup
		end
	end

end #classSession
