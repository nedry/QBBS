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
    port, ip =Socket.unpack_sockaddr_in(@socket.getpeername)
    ip.gsub!(/[A-Za-z\:]/,"")
    return ip
  end

  def detect_ansi
    print "\e[s"			#Save Cursor Position
    print "\e[99B_"		#locate Cursor as far down as possible
    print "\e[6n"		  	#Get Cursor Position
    print "\e[u"			#Restore Cursor Position
    print "\e[0m_"		#Set Normal Colours

    print "\e[2J"		  	#Clear Screen
    print "\e[H"			#Home Cursor
    print "\e[1m\e[37m"

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


  def switchbaud(ansi)
		
	  if MULTIBBS then
			if ansi and File.exists?(TEXTPATH + "welcome0.ans") then
        fileout(TEXTPATH + "welcome0.ans")
    else
      fileout(TEXTPATH + "welcome0.txt")
    end
		displaysystems
		prompt = "Select system: "
		getinp(prompt) {|inp|
		happy = inp.upcase
		t = happy.to_i
		case happy
          when "CR"; crerror
          else
            if t > 0 and t <= t_total then
              return(t)
            end
          end #of case
        }
		end
end

  def logon
    ip= figureip(@socket.getpeername)
    print
    ddate = Time.now.strftime("%m/%d/%Y at %I:%M%p")
    add_log_entry(L_CONNECT,Time.now,"Connect from IP: #{ip}.")
    if detect_ansi then
      sleep(1)
      print "ANSI Detected"
      ansi = true
    else
      print "ANSI not Detected"
      ansi = false
    end
		
   theme_no = switchbaud(ansi)
	 path = TEXTPATH
	 
	 if !theme_no.nil? then
		 theme = fetch_theme(theme_no)
		 path = theme.text_directory
	 end
   # spam
	 # print VER
    print ("IP Address detected: #{ip}")
		fnpoint = ""
		fnpoint  = ".#{FIDOPOINT}" if FIDOPOINT != 0 
    print ("Fidonet Node: #{FIDOZONE}:#{FIDONET}/#{FIDONODE}#{fnpoint}")
    if ansi and File.exists?(path + "welcome1.ans") then
      fileout(path + "welcome1.ans")
    else
      fileout(path + "welcome1.txt")
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
            newuser(username, ip,theme_no)
            break
          else
            next # input name again
          end
        end

        password = getpwd("Enter password for user #{username}: ")
       if check_password(username.upcase, password) then
					checkmultiplelogon
					@c_user = fetch_user(get_uid(username))
					@node = addtowholist
          @who.each {|who| add_page(get_uid("SYSTEM"),who.c_alias,"*** #{@c_user.name} has just logged into the system.",true)}
          defaulttheme
        break 
			end
        checkmaxpwdmiss(count,username)
      else
        print "User IDs must be between 3 and 25 characters, and may not contain"
        print "the characters : * @ , ' "
      end
    end #of while...true

    checkkillfile(username)
    
		
    logandgreetuser(username, ip,theme_no)


  end

  def checkmaxsessions
    toomany = @who.len
    if toomany >= NODES then
      add_log_entry(L_SECURITY ,Time.now,"Maximum Sessions Exceeded!")

      fileout(TEXTPATH + "toomany.txt")
      sleep(10)
      hangup
    end
  end

  def newuser(username, ip,theme_no)
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
      else
        break
      end
    end
    prompt = "Enter your Location:            : "
    location = getinputlen(prompt,ECHO,6,false)
    prompt = "ANSI [IBM] Graphics        [Y,n]? "
    ansi = yes(prompt,true,false,true)
    prompt = "Full Screen Editor         [Y,n]? "
    fullscreen = yes(prompt,true,false,true)
    prompt = "MORE prompt                [Y,n]? "
    more =yes(prompt,true,false,true)
    chatalias = username.gsub(/\W/,"").slice(0..14)
    print "Your chat alias is #{chatalias}."
    print "You may change it in the user configuation menu."
    yes("Press <--^: ",true,false,true)
    add_user(username,ip,password,location,address,24,80,ansi, more, DEFLEVEL, fullscreen,"")
    @c_user = fetch_user(get_uid(username))
		@node = addtowholist
    add_log_entry(L_USER,Time.now,"New user #{@c_user.name} created.")
    @logged_on = true
 		if !theme_no.nil? then
			theme = fetch_theme(theme_no) #change to get default theme
      add_theme_to_user(@c_user,theme)
		else
      defaulttheme  #prevent crash in case user has no theme, set the default.
		end
    if s_total > 0 then
      screen = fetch_screen(1)
      add_screen_to_user(@c_user,screen)
    end

    ogfileout("newuser",2,true)
    yes("Press <--^: ",true,false,true)
    system = fetch_system
    system.newu_today += 1
    update_system(system)
    themes(nil)  if theme_no.nil? #set a theme for the user

  end

  def checkkillfile(username)
    @c_user = fetch_user(get_uid(username))
    if @c_user.deleted then
      add_log_entry(L_SECURITY,Time.now,"#{@c_user.name} tried to log on, but is in the kill file!")
      gfileout("killfile")
      sleep(10)
      hangup
    end
  end

  def checkmultiplelogon
    for x in 0..(@who.len - 1)
      if @who[x].name.upcase == @c_user.name.upcase then
        add_log_entry(L_SECURITY,Time.now,"#{@c_user.name} multiple logon attempt.")
        gfileout("already")
        sleep(10)
        hangup
      end
    end
  end

  def add_user_to_wall
    add_wall(@c_user.number,"","Telnet")
    wall_cull
  end

  def  display_wall
    i = 0
    j = 0
    cont = true

    if !wall_empty  then
      hcols = %w(WY WG WR).map {|i| "%"+i +";"}
      cols = %w(Y G R).map {|i| "%"+i +";"}
      headings = %w(Name Time-On Connection)
      widths = [30,20,10]
      header = hcols.zip(headings).map {|a,b| a+b}.formatrow(widths) +"%W;"
      underscore = cols.zip(['-'*30]*5).map{|a,b| a+b}.formatrow(widths)
      print header
      print underscore if !@c_user.ansi
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
      print""
    else
      print "List has been cleared"
    end

  end

  def logandgreetuser(username, ip,theme_no)
    clear_system_pages(@c_user)
    system = fetch_system
    system.total_logons += 1
    system.logons_today += 1
		if !theme_no.nil? then
			theme = fetch_theme(theme_no) #change to get default theme
      add_theme_to_user(@c_user,theme)
		else
      defaulttheme  #prevent crash in case user has no theme, set the default.
		end
    add_log_entry(L_USER,Time.now,"#{@c_user.name} logged on sucessfully.")
    @logged_on = true
    @debuglog.push("-SA: Logon - #{@c_user.name}")
    @c_user.logons = @c_user.logons.succ
    @c_user.ip = ip
    add_user_to_wall
    update_user(@c_user)
    update_system(system)
    @cmd_hash = hash_commands(@c_user.theme_key)
    ogfileout("welcome2",4,true) if !@c_user.fastlogon
    @c_user.laston = Time.now

    if @c_user.fastlogon
      print
      print "%WR;Fast User Logon Mode %YR;On%WR;.  Skipping Logon Information.%W;"
      print "This may be changed at the User Configuration Menu."
      print
    end


  end

  def qotd
    if !QOTD.nil? then
      print
      print "Quote of the Day: " if !existfileout('qotdhdr',0,true)
      print quoteFromDir(QOTD)
    else
      print
      print "%WG;Quote of the Day is disabled%W;"
      print
    end
  end



  def checkmaxpwdmiss(count,username)
    if count == MAXPASSWORDMISS then
      fileout(TEXTPATH + "missed.txt")
      add_log_entry(L_SECURITY,Time.now,"#{username} password missed: #{MAXPASSWORDMISS} -- disconnected.")
      sleep(10)
      hangup
    end
  end

end #classSession
