class Session
	def usersettingsmenu
		print <<-here
		%BTerminal Settings                   
		%G(%YC%G)hat Alias                      %G(%YF%G)ull Screen Editor
		%G(%YG%G)raphics (ANSI) Toggle          %G(%YL%G)ines per Page     
		%G(%YP%G)assword                        %G(%YM%G)ore Prompt Toggle
		%G(%YW%G)idth                           %G(%YQ%G)uit
		%G(%YZ%G)Zip Read Settings              %G(%Y?%G)This Menu
		here
	end

	def defaultalias(username)
		newname = username.split.each {|subname| subname.capitalize!}.to_s
		x = 0
		while true
			break if !alias_exists(newname) 
			x = x.succ
			newname << x.to_s
		end
		return newname
	end

	def usersettings
		usersettingsmenu if !existfileout('usersetmnu',0,true)	
		prompt = "%WChange Which User Setting ? %Y<--^%W to quit: " 
		getinp(prompt,false) {|inp|
			
			if !inp.integer?
			 parameters = Parse.parse(inp)
			 inp.gsub!(/[-\d]/,"")
			end
			case inp.upcase
			when "L"; changelength
			when "W"; changewidth
			when "P"; changepwd
			when "C"; changenick
			when "G"; togglegraphics 
			when "M"; togglemore
			when "F"; togglefull
			when "Z"; changezip(parameters)
			when "?"; usersettingsmenu if !existfileout('usersetmnu',0,true)	
			when "";	done = true
			end
			done
		}
	end 
end #class Session

def changelength
	print "Screen Length is %R#{@c_user.length}%G lines."
	prompt = "Screen length? (10-60) [default=40]: "
	@c_user.length = getnum(prompt,10,60) || 40
	update_user(@c_user,get_uid(@c_user.name))
end

def changewidth
	print "Screen Width is %R#{@c_user.width}%G characters."
	prompt = "Screen width? (22-80) [default=40]: "
	@c_user.width = getnum(prompt,22,80) || 40
	update_user(@c_user,get_uid(@c_user.name))
end

def changepwd
	prompt = "Enter Current Password: "
	tempstr = getpwd(prompt)
	if tempstr == @c_user.password then
		if (pswd2 = getandconfirmpwd)
			print "Password Changed."
			@c_user.password = pswd2
			update_user(@c_user,get_uid(@c_user.name))
		else
			print "Aborted - Password not changed"
		end
	else 
		print "You must enter your old password correctly." 
	end
end

def changenick
	if @c_user.alais == '' then 
		@c_user.alais = defaultalias(@c_user.name)
		update_user(@c_user,get_uid(@c_user.name))
	end

	print <<-here
	This is the name you will be known as in Teleconference.  
	No Spaces are allowed. If you enter a space, it will be removed.  
	No inappropriate names please.

	Your current Chat Alias is %Y#{@c_user.alais}%G.
	here

	prompt = "Enter Chat Alias (Max 15 Characters): %Y"
	tempstr = getinp(prompt,false)
	if tempstr == '' then
		print "%RNot Changed%G" 
		return
	end
	newname = tempstr.strip.split.to_s.slice(0..14)
	if !alias_exists(newname) then 
		@c_user.alais = newname
		update_user(@c_user,get_uid(@c_user.name))
	else 
		print "%RThat alias is in use by another user.%G" 
	end
end

def togglegraphics
	if @c_user.ansi == TRUE 
		print "Graphics Now Off"
		@c_user.ansi = FALSE
	else
		@c_user.ansi = TRUE
		print "Graphics Now On"
	end
	update_user(@c_user,get_uid(@c_user.name))
end

def togglefull
	if @c_user.fullscreen == TRUE 
		print "Using Line Editor"
		@c_user.fullscreen = FALSE
	else
		@c_user.fullscreen = TRUE
		print "Using Full Screen Editor"
	end
	update_user(@c_user,get_uid(@c_user.name))
end

def togglemore
	if @c_user.more == TRUE 
		print "More Prompt Now %ROff"
		@c_user.more = FALSE
	else
		@c_user.more = TRUE
		print "More Prompt Now %GOn"
	end
	update_user(@c_user,get_uid(@c_user.name))
end

def displayzipheader
  print "%W#      %BBoard Description                    %WInclude?"
  print "%W--     %B-----------------                    %W--------"
 end

def zipfix
 @c_user.zipread = [] if @c_user.zipread == nil 
 for i in 0..(a_total - 1)
  @c_user.zipread[i] = true if @c_user.zipread[i] == nil  
 end
 end
 
 def displayziplist

  displayzipheader
  zipfix
  more = 0
  cont = true
   for i in 1..(a_total - 1)

   area = fetch_area(i)
   l_read = 0
   a_name = area.name
   prompt = "%WMore (Y,n) or Toggle #? "
   user = @c_user
   if (user.areaaccess[i] != "I") or (user.level == 255)
    more += 1
    write "%W#{i.to_s.ljust(5)}  %B#{a_name.ljust(40)}"
    if user.zipread[i] == true then print "%Wyes" else print "no" end
    if more > 19 then
     cont = yes_num(prompt,true,true)
     more = 0
    end
    
    break if !cont or cont.kind_of?(Fixnum)
   end
 end
  return cont
 end
 
 def changezip(parameters)
 
 
  if (parameters[0] > -1) then 
   tempint = parameters[0] 
  else
    tempint = displayziplist
    tempint = nil if !tempint.kind_of?(Fixnum)
  end
  
  while true
   if tempint.nil?  then
    prompt = CRLF+"%WArea to toggle (1-#{(a_total - 1)}) ? %Y<--^%W to quit:  " 
    happy = getinp(prompt,false).upcase
    tempint = happy.to_i
   end
    case happy
     when ""; break
     when "?"
       tempint = displayziplist
       tempint = nil if !tempint.kind_of?(Fixnum)
    #else 
    end
     if (1..(a_total - 1)).include?(tempint)
      t = @c_user.areaaccess[tempint]
      if t !~ /[NI]/ or (@c_user.level == 255)
       @c_user.zipread[tempint] = !@c_user.zipread[tempint]
       update_user(@c_user,get_uid(@c_user.name))
       area = fetch_area(tempint)
       out = "will not"
       out = "will" if @c_user.zipread[tempint]
       print
       print "%GArea #{area.name} %R#{out}%G be automatically read in Zipread."
       print
       tempint = nil
     else
      if t == "N" then 
       print "%RYou do not have access." 
       break
      end
      tempint = nil
     end # of if
     else tempint = nil
    end #of if in range
   #end #of case
  end # of while true
 end # of def
