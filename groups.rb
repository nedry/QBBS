 class Session
 
 
  def displaygroup(number)
    group = fetch_group(number)
    write "\r\n%R#%W#{number} %G #{group.groupname}"
    write "%R [DELETED]" if group.delete
    print ""
    print "%CQWK/REP Mapping:"
    print 
  if !get_qwknet(group).nil? then
    qwknet = get_qwknet(group)
    
    print " %G[%YQN%G]ame: %Y#{qwknet.name}"
    print " %G[%YQU%G]Local QWK account: %Y#{qwknet.qwkuser}"
    print " %G[%YB%G]BSid: %Y#{qwknet.bbsid}"
    print " %G[%YRD%G]Rep Directory: %Y#{qwknet.repdir}"
    print " %G[%YRP%G]Rep Packet: %Y#{qwknet.reppacket}"
    print " %G[%YQP%G]QWK Directory: %Y#{qwknet.qwkdir}"
    print " %G[%YQP%G]QWK Packet: %Y#{qwknet.qwkpacket}"
    print " %G[%YQT%G]QWK Tag:"
    print "  %Y#{qwknet.qwktag}"
    print " %G[%YFA%G]FTP Address: %Y#{qwknet.ftpaddress}"
    print " %G[%YFC%G]FTP User: %Y#{qwknet.ftpaccount}"
    print " %G[%YFP%G]FTP Password: %Y#{qwknet.ftppassword}"
    print " %G[%Y?%G]More Options"
    print
  else
   print " %CNo QWK network assigned.%W"
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
      when "B";changebbsid(gpointer)
      when "Q"; gpointer = true
      when "NQ"; qwknetadd(gpointer)
      when "QN"; changeqwkname(gpointer)
      when "RD";  changerepdirectory(gpointer)
      when "RP"; changereppacket(gpointer)
      when "QD";  changeqwkdirectory(gpointer)
      when "QP"; changeqwkpacket(gpointer)
      when "QR"; qwknetremove(gpointer)
      when "QT"; changeqwktag(gpointer)
      when "QN"; changeqwkname(gpointer)
      when "QU"; changeqwklocalaccount(gpointer)
      when "FA"; changeftpaddress(gpointer)
      when "FC"; changeftpaccount(gpointer)
      when "FP";  changeftppassword(gpointer)
      when "A"; gpointer = addgroup
      when "W"; displaywho
      when "PU"; page
      when "N"; changegroupname(gpointer)
      when "D"; deletegroup(gpointer)
      when "G"; leave
      when "?"; gfileout ("groupmnu")
      end # of case
      p_return = [gpointer,(g_total - 1)]
    }
  end
  
  def changeftppassword(number)
    
  group = fetch_group(number)
  qwknet = get_qwknet(group)   
   if !qwknet.nil? then

      prompt = "%WEnter the FTP Password:%G  "
      ftppassword = getinp(prompt) 
      
      if ftppassword.length > 40 then
        print "%RPassword too long. 40 Character Maximum"
      else
        if ftppassword == "" then
          print "%RCancelled"
        else
          qwknet.ftppassword = ftppassword
          update_qwknet(qwknet)
        end
      end
    else
      print "No QWK/NET Network defined."
    end
    displaygroup(number)
 end
 
  def changeftpaddress(number)
    
  group = fetch_group(number)
  qwknet = get_qwknet(group)   
   if !qwknet.nil? then

      prompt = "%WEnter the FTP Address:%G  "
      ftpaddress = getinp(prompt) 
      
      if ftpaddress.length > 40 then
        print "%RAddress too long. 40 Character Maximum"
      else
        if ftpaddress == "" then
          print "%RCancelled"
        else
          qwknet.ftpaddress = ftpaddress
          update_qwknet(qwknet)
        end
      end
    else
      print "No QWK/NET Network defined."
    end
    displaygroup(number)
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
  
def changeftpaccount(number)
    
  group = fetch_group(number)
  qwknet = get_qwknet(group)   
   if !qwknet.nil? then

      prompt = "%WEnter the FTP UserID:%G  "
      ftpaccount = getinp(prompt) 
      
      if ftpaccount.length > 40 then
        print "%RUserID too long. 40 Character Maximum"
      else
        if ftpaccount == "" then
          print "%RCancelled"
        else
          qwknet.ftpaccount = ftpaccount
          update_qwknet(qwknet)
        end
      end
    else
      print "No QWK/NET Network defined."
    end
    displaygroup(number)
 end
 
 
def changeqwktag(number)
    
  group = fetch_group(number)
  qwknet = get_qwknet(group)   
   if !qwknet.nil? then

      prompt = "%WEnter the QWK  tag:%G  "
      qwktag = getinp(prompt) 
      
      if qwktag.length > 78 then
        print "%RTag too long. 78 Character Maximum"
      else
        if qwktag == "" then
          print "%RCancelled"
        else
          qwknet.qwktag =  convert_to_utf8(qwktag)
          update_qwknet(qwknet)
        end
      end
    else
      print "No QWK/NET Network defined."
    end
    displaygroup(number)
 end
 
def changebbsid(number)
    
  group = fetch_group(number)
  qwknet = get_qwknet(group)   
   if !qwknet.nil? then

      prompt = "%WEnter the BBSID of the remote system:%G "
      bbsid = getinp(prompt) 
      
      if bbsid.length > 40 then
        print "%RName too long. 40 Character Maximum"
      else
        if bbsid == "" then
          print "%RCancelled"
        else
          bbsid.upcase!
          qwknet.bbsid = bbsid
          update_qwknet(qwknet)
        end
      end
    else
      print "No QWK/NET Network defined."
    end
    displaygroup(number)
 end

def changeqwkdirectory(number)
    
  group = fetch_group(number)
  qwknet = get_qwknet(group)   
   if !qwknet.nil? then

      prompt = "%WEnter the path for QWK packets:%G "
      qwkdir = getinp(prompt) 
      
      if qwkdir.length > 40 then
        print "%RPath too long. 40 Character Maximum"
      else
        if qwkdir == "" then
          print "%RCancelled"
        else
          qwknet.qwkdir = qwkdir
          update_qwknet(qwknet)
        end
      end
    else
      print "No QWK/NET Network defined."
    end
    displaygroup(number)
 end
 
 def changeqwkpacket(number)
    
  group = fetch_group(number)
  qwknet = get_qwknet(group)   
   if !qwknet.nil? then

      prompt = "%WEnter the file name for QWK packets:%G "
      qwkpacket = getinp(prompt) 
      
      if qwkpacket.length > 40 then
        print "%RFilename too long. 40 Character Maximum"
      else
        if qwkpacket == "" then
          print "%RCancelled"
        else
          qwknet.qwkpacket = qwkpacket
          update_qwknet(qwknet)
        end
      end
    else
      print "No QWK/NET Network defined."
    end
    displaygroup(number)
 end

def changerepdirectory(number)
    
  group = fetch_group(number)
  qwknet = get_qwknet(group)   
   if !qwknet.nil? then

      prompt = "%WEnter the path for REP packets:%G "
      repdir = getinp(prompt) 
      
      if repdir.length > 40 then
        print "%RPath too long. 40 Character Maximum"
      else
        if repdir == "" then
          print "%RCancelled"
        else
          qwknet.repdir = repdir
          update_qwknet(qwknet)
        end
      end
    else
      print "No QWK/NET Network defined."
    end
    displaygroup(number)
 end
 
 def changereppacket(number)
    
  group = fetch_group(number)
  qwknet = get_qwknet(group)   
   if !qwknet.nil? then

      prompt = "%WEnter the file name for REP packets:%G "
      reppacket = getinp(prompt) 
      
      if reppacket.length > 40 then
        print "%RFilename too long. 40 Character Maximum"
      else
        if reppacket == "" then
          print "%RCancelled"
        else
          qwknet.reppacket = reppacket
          update_qwknet(qwknet)
        end
      end
    else
      print "No QWK/NET Network defined."
    end
    displaygroup(number)
 end

 
def changeqwkname(number)
    
  group = fetch_group(number)
  qwknet = get_qwknet(group)   
   if !qwknet.nil? then

      prompt = "%WEnter QWK/REP network name:%G "
      name = getinp(prompt) 
      
      if name.length > 40 then
        print "%RName too long. 40 Character Maximum"
      else
        if name == "" then
          print "%RCancelled"
        else
          qwknet.name = name
          update_qwknet(qwknet)
        end
      end
    else
      print "No QWK/NET Network defined."
    end
    displaygroup(number)
 end
 
 
 def changeqwklocalaccount(number)
    
  group = fetch_group(number)
  qwknet = get_qwknet(group)   
   if !qwknet.nil? then

      prompt = "%WEnter the User ID of QWK/REP service account on the LOCAL system:%G "
      account = getinp(prompt) 
      
      if account.length > 40 then
        print "%RAccount too long. 40 Character Maximum"
      else
        if account == "" then
          print "%RCancelled"
        else
          if !user_exists(account) then
            print "%RLocal user does not exist.  Try again..."
          else
            qwknet.qwkuser = account
            update_qwknet(qwknet)
          end
        end
      end
    else
      print "No QWK/NET Network defined."
    end
    displaygroup(number)
 end
 
  def qwknetadd(number)
    
    group = fetch_group(number)
  if get_qwknet(group).nil? then
    while true
      prompt = "Enter QWK/REP network name:%G "
      name = getinp(prompt)
      if name == "" then
        print "%RCancelled"
        return [gpointer,(g_total - 1)]
      end
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
        if !user_exists(qwkuser) then
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
      name = getinp(prompt) 
      if name == "" then
        print "%RCancelled"
        return
      end
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

      prompt = "Enter new group name: "
      name = getinp(prompt) 
      if name == "" then
        print "%RCancelled"
      else
      if name.length > 40 then
        print "Name too long. 40 Character Maximum"
      else 
    group.name = name
    update_area(group)
    print
  end
end
end

 
end # class Session

