 class Session
 
 
  def displaygroup(number)
    group = fetch_group(number)
    write "\r\n%R#%W#{number} %G #{group.groupname}"
    write "%R [DELETED]" if group.delete
    print ""
    
  if !get_qwknet(group).nil? then
    qwknet = get_qwknet(group)
    print "QWK/REP Mapping:"
    print "%G[%YN%G]ame: %Y#{qwknet.name}"
    print "%G[%YQU%G]Local QWK account: %Y#{qwknet.qwkuser}"
    print "%G[%YB%G]BSid: %Y#{qwknet.bbsid}"
    print "%G[%YRD%G]Rep Data: %Y#{qwknet.repdir}"
    print "%G[%YRP%G]Rep Packet: %Y#{qwknet.reppacket}"

    print "%G[%YQP%G]QWK Dir: %Y#{qwknet.qwkdir}"
    print "%G[%YQP%G]QWK Packet: %Y#{qwknet.qwkpacket}"
    print "%G[%YMI%G]QWK Mail Incoming Area #: %Y#{qwknet.qwkmail}"
    print "%G[%YQT%G]QWK tag:"
    print " %Y#{qwknet.qwktag}"
    print "%G[%YFA%G]FTP address: %Y#{qwknet.ftpaddress}"
    print "%G[%YFC%G]FTP user: %Y#{qwknet.ftpaccount}"
    print "%G[%YFP%G]FTP user: %Y#{qwknet.ftppassword}"
  else
   print
   print "%RNo QWK network assigned to this group.%W"
  end
  

  end #displaygroup

  def groupmaintmenu
    readmenu(
      :initval => 0,
      :range => 0..(g_total - 1),
      :prompt => '"%W#{sdir} Group [%p] (0-#{g_total - 1}): "'
    ) {|sel, gpointer, moved|
      displaygroup(gpointer) if moved
      case sel
      when "/"; displaygroup(gpointer)
      when "Q"; gpointer = true
      when "QN"; qwknetadd(gpointer)
      when "QD"; qwknetremove(gpointer)
      when "A"; gpointer = addgroup
      when "W"; displaywho
      when "PU"; page
      when "N"; changegroupname(gpointer)
      when "D"; deletegroup(gpointer)
      when "G"; leave
      when "?"; gfileout ("areamnu")
      end # of case
      p_return = [gpointer,(g_total - 1)]
    }
  end
  
  def qwknetremove(number)
    group = fetch_group(number)
    
    if  get_qwknet(group).nil? then
      print "%RNo QWK network to delete"
    else
      print "%RWARNING: %YThis action is permenent and may cause damage.%W"
      commit = yes("Are you sure #{YESNO}",true,false,true)
      if commit then
        remove_qwknet(group)
      else
        print "Cancelled."
      end
    end
      
  end 
  
  
  def qwknetadd(number)
    
    group = fetch_group(number)
  if get_qwknet(group).nil? then
    while true
      prompt = "Enter QWK/REP network name:%G "
      name = getinp(prompt) {|n| n != ""}
      if name.length > 40 then
        print "%RName too long. 40 Character Maximum"
      else break end
    end
    
   while true
      prompt = "%WEnter the BBSID of the remote system:%G "
      bbsid = getinp(prompt) {|n| n != ""}
      if bbsid.length > 40 then
        print "%RName too long. 40 Character Maximum"
      else break end
    end
    
   while true
      prompt = "%WEnter the User ID of QWK/REP service account on the LOCAL system:%G "
      qwkuser = getinp(prompt) {|n| n != ""}
      if qwkuser.length > 40 then
        print "%RName too long. 40 Character Maximum"
      else
        if ! user_exists(qwkuser) then
          print "%RLocal user does not exist.  Try again..."
        else
         break 
       end
     end
   end
   
   while true
      prompt = "%WEnter the User ID of QWK/REP ftp account on the REMOTE system:%G "
      ftpaccount = getinp(prompt) {|n| n != ""}
      if ftpaccount.length > 40 then
        print "%RName too long. 40 Character Maximum"
      else break end
    end
    
   while true
      prompt = "%WEnter the ftp account address on the REMOTE system:%G "
      ftpaddress = getinp(prompt) {|n| n != ""}
      if ftpaddress.length > 40 then
        print "%RName too long. 40 Character Maximum"
      else break end
    end
  
  while true
      prompt = "%WEnter the ftp account password on the REMOTE system:%G "
      ftppassword = getinp(prompt) {|n| n != ""}
      if ftppassword.length > 40 then
        print "%RName too long. 40 Character Maximum"
      else break end
    end
    

      commit = yes("Are you sure #{YESNO}",true,false,true)
      if commit then
        add_qwknet(group,name,bbsid,qwkuser,ftpaddress,ftpaccount,ftppassword)
      else
        print "%RCancelled."
        return
      end
  else
    print "%RYou may only have one QWK network per message group."
  end
  end

  def deletegroup(gpointer)
    if gpointer <= 1
      print "%RYou cannot delete group 0 or 1."
      return
    end

    group = fetch_area(gpointer)

    if group.delete
      area.delete = false
      print "Group ##{gpointer} UNdeleted"
    else
      group.delete = true
      print "Group ##{gpointer} deleted."
    end
    update_group(group)
  end


  def addgroup

    while true
      prompt = "Enter new group name: "
      name = getinp(prompt) {|n| n != ""}
      if name.length > 40 then
        print "%RName too long. 40 Character Maximum"
      else break end
    end

      commit = yes("Are you sure #{YESNO}",true,false,true)
      if commit then
        add_group(name)
        gpointer = g_total - 1
      else
        print "%RCancelled."
        gpointer = g_total - 1
        return
      end

  end



  def changegroupname(gpointer)

    group = fetch_group(gpointer)

    while true
      prompt = "Enter new group name: "
      name = getinp(prompt) {|n| n != ""}
      if name.length > 40 then
        print "Name too long. 40 Character Maximum"
      else break end
    end
    group.name = name
    update_area(group)
    print
  end

 
end # class Session

