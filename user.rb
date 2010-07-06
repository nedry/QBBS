class Session

  def showareas 
    print "Under Construction"
  end

  def displayuser(number)
    user = fetch_user(number)
    ldate = user.laston.strftime("%A %B %d, %Y / %I:%M%p (%Z)") 
    write "%R#%W#{number} %G #{user.name}"
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

    for i in 0..20
      pointer = get_pointer(@c_user,i)
      if pointer.nil? then write "-" else write pointer.access end
    end
    print 
    print 
    print 
  end #displayuser

  def usermenu 
    total = u_total
    oprompt = '"%W#{sdir}User [%p] (1-#{u_total}): "'
    readmenu(
      :initval => 1,
      :range => 1..(u_total ),
      :prompt => oprompt
    ) {|sel, upointer, moved|
      if !sel.integer?
        sel.gsub!(/[-\d+]/,"")
      end

      displayuser(upointer+1) if moved
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
   
    prompt = "%WMessage Area to Change (0 - #{(a_total)})<?: list, Q: Quit>: "
    tempstr = ''
    getinp(prompt) {|inp|
      tempstr = inp.upcase
      showareas if tempstr == "?"
      ((tempstr =~ /[0Q]/) or (tempstr.to_i > 0)) ? true : false
    }
    tempint2 = tempstr.to_i
    puts user.number
    puts tempint2
     pointer = get_pointer(user,tempint2)
    
     

    if tempstr != "Q" then
      if (0..a_total).include?(tempint2)
        prompt = "%GEnter new access level for area #{tempint2}: "
        tempstr2 = getinp(prompt).upcase
        if tempstr2 =~ /[NIWRMC]/
          pointer.access = tempstr2
          print "Area #{tempint2} access changed to #{tempstr2}"
	   update_pointer(pointer)
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
