class Session

  def showareas 
    print "Under Construction"
  end

  def displayuser(number)
    user = fetch_user(number)
    ldate = user.laston.strftime("%A %B %d, %Y / %I:%M%p (%Z)") 
    write "%R;#%W;#{number} %G; #{user.name}"
    write "%WR; [DELETED]%W;" if user.deleted 
    write "%WG; [LOCKED]%W;" if user.locked
    print ""
    print <<-here
    %C;Last IP:       %G;#{user.ip}
    %C;Email Address: %G;#{user.address}
    %C;Location:      %G;#{user.citystate}
    %C;Last On:       %G;#{ldate}
    %C;Password:      %G;********   %C;Level: %G;#{user.level}
    %C;RSTS Password: %G;#{user.rsts_pw}
    %C;RSTS Account:  %G;#{RSTS_BASE},#{user.rsts_acc}
    here
    print "%Y;                         1         2         3         4" 
    print "%Y;Area#:         01234567890123456789012345678901234567890"

    write "%Y;Access:%W;        "

    
    for i in 0..40
      pointers = get_all_pointers(user)
      if i <  pointers.length then 
	case pointers[i].access
	  when "N"; write "%WR;N"	
	  when "I"; write "%WR;I"
	  when "R"; write "%W;R"
	  when "W"; write "%WG;W"
	  when "C"; write "%WM;C"
	  when "M"; write "%WC;M"
	end
      else write "%W;-" 
      end
    end
    write  "%W;"
    print 
    print 
    print 
  end #displayuser

  def usermenu 
    total = u_total
    readmenu(
      :initval => 1,
      :range => 1..(u_total ),
      :loc => USER
    ) {|sel, upointer, moved|
      if !sel.integer?
        sel.gsub!(/[-\d+]/,"")
      end

      displayuser(upointer) if moved
      case sel
      when "/"; showuser(upointer)
      when "Q"; upointer = true
      when "A"; changeaccess(upointer)
      when "L"; changeuserlevel(upointer)
      when "N"; changeusername(upointer)
      when "AD"; changeuseremail(upointer)
      when "RA" ; changersts_acc(upointer)
      when "K"; deleteuser(upointer)
      when "W"; displaywho
      when "PU"; page    
      when "S"; lockuser(upointer)
      when "P"; changepass(upointer)
      when "LO"; changelocation(upointer)
      when "G"; leave
      when "?"; gfileout ("usermnu")
      end # of case
      p_return = [upointer,u_total ]

    }
  end

  def showuser(upointer)
      u_scanforaccess(upointer)
    if u_total > -1 then
      displayuser(upointer)
    else 
      print
      print "%RNo Users.  Something is really fucked up!"
    end
  end
  
    def u_scanforaccess(upointer)
    user = fetch_user(upointer)
    for i in 0..(a_total - 1) do
      area = fetch_area(i)
       pointer = get_pointer(user,i)
       if pointer.nil? then 
	add_pointer(user,i,area.d_access,0)
      end
    end
  end


  def changeaccess(upointer)
    u_scanforaccess(upointer)
    user = fetch_user(upointer)
   
    prompt = "%W;Message Area to Change (0 - #{(a_total)})<?: list, Q: Quit>: "
    tempstr = ''
    getinp(prompt) {|inp|
      tempstr = inp.upcase
      showareas if tempstr == "?"
      ((tempstr =~ /[0Q]/) or (tempstr.to_i > 0)) ? true : false
    }
    tempint2 = tempstr.to_i
     pointer = get_pointer(user,tempint2)
    
     

    if tempstr != "Q" then
      if (0..a_total).include?(tempint2)
        prompt = "%G;Enter new access level for area #{tempint2}%W;: "
        tempstr2 = getinp(prompt).upcase
        if tempstr2 =~ /[NIWRMC]/
          pointer.access = tempstr2
          print "Area #{tempint2} access changed to #{tempstr2}"
	   update_pointer(pointer)
        else
          print "%WR;Out of Range%W;"
        end
      end
    end
  end

  def changeuserlevel(upointer)
    user = fetch_user(upointer)
    prompt = "%W;User Level? (1-255): "
    if upointer != 0 then
      tempint = getnum(prompt,1,255)
      if !tempint.nil? then
        user.level = tempint
        update_user(user)
      else
        print "%WR;Cancelled.%W;"
        return
      end
    else
      print "%WR;You cannot change the access of the SYSOP%W;"
    end
  end

  def changersts_acc(upointer)
    user = fetch_user(upointer)
    prompt = "%W;RSTS Account? (1-254): "

    user.rsts_acc = getnum(prompt,0,254)
    update_user(user)
  end

  def changeusername(upointer)
    user = fetch_user(upointer)
    prompt = "%W;User Name?: "
    if upointer != 0 then
      user.name = getinp(prompt).slice(0..24)
      update_user(user)
    else 
      print "%WR;You cannot change the name of the SYSOP%W;" 
    end
  end

  def changelocation(upointer)
    user = fetch_user(upointer)
    prompt = "%W;Location?: "

    user.citystate = getinp(prompt).slice(0..40)
    update_user(user)

  end

  def changeuseremail(upointer)
    user = fetch_user(upointer)
    prompt = "%W;Enter new email address: "
    address = getinp(prompt)
    user.address = address
    update_user(user)
    print
  end



  def deleteuser(upointer)
    user = fetch_user(upointer)
    if upointer > 0 then
      if user.deleted then
        user.deleted = false
        print "%WG;User ##{upointer} UNdeleted%W;"
      else 
        user.deleted = true
        print "%WR;User ##{upointer} deleted.%W;"
      end
      update_user(user)
    else
      print "%WR%You cannot delete the SYSOP.%W%" 
    end
  end

  def lockuser(upointer)
    user = fetch_user(upointer)
    if user.locked then
      user.locked = false
      print "%WG;User ##{upointer} UNlocked%W;"
    else 
      user.locked = true
      print "%WR;User ##{upointer} locked.%W;"
    end
    update_user(user)
  end

  def changepass(upointer)
    user = fetch_user(upointer)
    pswd = getpwd("%W;Enter new password: ").strip.upcase 
    pswd2 = getpwd("Enter again to confirm: ").strip.upcase 
    if pswd == pswd2
      print "%WG;Password Changed.%W;"
      user.password = pswd2
      update_user(user)
    else 
      print "%WR;Passwords don't match.  Try again.%W;" 
    end
  end

end #class Session
