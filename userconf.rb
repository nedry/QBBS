class Session
  def usersettingsmenu
    existfileout('usersethdr',0,true)
    print "%G;Please select one of the following:\r\n"
    print "    %C;C  %Y;... Chat Alias: %W;#{@c_user.alias}"
    print "    %C;E  %Y;... Full Screen Editor: %W;#{@c_user.fullscreen ? "On" : "Off"}"
    print "    %C;G  %Y;... Graphics (ANSI): %W;#{@c_user.ansi ? "On" : "Off"}"          
    print "    %C;F  %Y;... Fast Logon: %W;#{@c_user.fastlogon ? "On" : "Off"}" 
    print "    %C;L  %Y;... Lines per Page: %W;#{@c_user.length}"    
    print "    %C;M  %Y;... More Prompt: %W;#{@c_user.more ? "On" : "Off"}"
    print "    %C;W  %Y;... Width: %W;#{@c_user.width}"
    print "    %C;P  %Y;... Password"               
    print "    %C;SI %Y;... Signature"		
    print "    %C;Z  %Y;... Zip Read Settings"
    print "    %C;T  %Y;... Theme"
    if SCREENSAVER
      saver = "NONE"
      saver = get_user_screen(@c_user).name if !get_user_screen(@c_user).nil?
      print "    %C;S  %Y;... Screen Saver: %W;#{saver}"
    end
    print
  end

  def defaultalias(username)
    newname = ""
    newname = username.gsub(/\W/,"").slice(0..14)

    x = 0
    while true
      break if !alias_exists(newname) 
      x = x.succ
      newname << x.to_s
    end
    return newname
  end

  def usersettings

    while true
    theme = get_user_theme(@c_user) 
    usersettingsmenu	
    prompt = theme.user_prompt
    inp = getinp(prompt) 
      if !inp.integer?
        parameters = Parse.parse(inp)
        inp.gsub!(/[-\d]/,"")
      end
      case inp.upcase
      when "L"; changeusernum("screen length (10-60) [24 is normal]",10,40,false,Proc.new{|temp| @c_user.length = temp})
      when "W"; changeusernum("screen width (22-80) [80 is normal]",22,80,false,Proc.new{|temp| @c_user.width = temp})
      when "P"; changepwd
      when "C"; changenick
      when "G"; togglegraphics 
      when "M"; togglemore
      when "E"; togglefull
      when "F"; togglefast
      when "Z"; changezip(parameters)
      when "T";  themes(parameters)
      when "S"; screensaver(parameters)
      when "SI"; signature
      when "?" 
        if !existfileout('usersethdr',0,true)
	  print "User Settings:"
        end
	usersettingsmenu
                      	      
      when "";	break
      when "Q";	break
      when "X";	break 
  end 
  end
  end
end #class Session


def signature
  print "Your current signature is:\n"
  if !@c_user.signature.nil? then
    print @c_user.signature
  else
    print "%WR;None%W;"
  end		
  change = yes("\nUpdate your signature? #{YESNO}",true,false,true)
	if change then
		saveit,title = lineedit(:maxsize => 5, :header =>"%G;Enter your signature.%Y;")
    if @lineeditor.msgtext.length > 0 then
		  @c_user.signature = @lineeditor.msgtext.join("\n")
		else
			print "%WR;Cleared%W;"
			@c_user.signature = nil
		end
	end
  update_user(@c_user)

end

def changepwd
  prompt = "Enter Current Password: "
  tempstr = getpwd(prompt)
  if tempstr == @c_user.password then
    if (pswd2 = getandconfirmpwd)
      print "Password Changed."
      @c_user.password = pswd2
      update_user(@c_user)
      usersettingsmenu
    else
      print "Aborted - Password not changed"
    end
  else 
    print "You must enter your old password correctly." 
  end
end

def changenick
  if @c_user.alias == '' then 
    @c_user.alias = defaultalias(@c_user.name)
    update_user(@c_user)
  end

  print <<-here
  This is the name you will be known as in Teleconference.  
  No Spaces are allowed. If you enter a space, it will be removed.  
  No inappropriate names please.

  Your current Chat Alias is %W;#{@c_user.alias}%G;.
  here

  prompt = "Enter Chat Alias (Max 15 Characters): %W;"
  tempstr = getinp(prompt)
  if tempstr == '' then
    print "%R;Not Changed%G;" 
    return
  end
  newname = tempstr.gsub(/\W/,"").slice(0..14)

  if !alias_exists(newname) then 
    @c_user.alias = newname
    update_user(@c_user)
  else 
    print "%R;That alias is in use by another user.%G;" 
  end
end

def togglegraphics
  @c_user.ansi = !@c_user.ansi
  update_user(@c_user)
end

def togglefull
  @c_user.fullscreen = !@c_user.fullscreen
  update_user(@c_user)
end

def togglefast
  @c_user.fastlogon = !@c_user.fastlogon
  update_user(@c_user)
end

def togglemore
  @c_user.more = !@c_user.more
  update_user(@c_user)
end

def displayzipheader
  print "%W;#      %B;Board Description                    %W;Include?"
  print "%W;--     %B;-----------------                    %W;--------"
end

def displayziplist

  displayzipheader
  scanforaccess
  more = 0
  cont = true
  for i in 1..(a_total - 1)

    area = fetch_area(i)
    l_read = 0
    a_name = area.name
    prompt = "%W;More (Y,n) or Toggle #? "
    user = @c_user
    pointer = get_pointer(@c_user,i)
    if (pointer.access[i] != "I") or (user.level == 255)
      more += 1
      write "%W#{i.to_s.ljust(5)}  %B#{a_name.ljust(40)}"
      print "#{pointer.zipread ? "Yes" : "No"}"
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
      prompt = CRLF+"%W;Area to toggle (1-#{(a_total - 1)}) ? %W;<--^%W; to quit:  " 
      happy = getinp(prompt).upcase
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
         pointer = get_pointer(@c_user,tempint)
      t = pointer.access
      if t !~ /[NI]/ or (@c_user.level == 255)
        pointer.zipread = !pointer.zipread
	update_pointer(pointer)
        area = fetch_area(tempint)
        out = "will not"
        out = "will" if pointer.zipread
        print
        print "%G;Area #{area.name} %R;#{out}%G; be automatically read in Zipread."
        print
        tempint = nil
      else
        if t == "N" then 
          print "%R;You do not have access." 
          break
        end
        tempint = nil
      end # of if
    else tempint = nil
    end #of if in range
    #end #of case
  end # of while true
end # of def
