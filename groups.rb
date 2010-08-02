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
      print " %G[%YRP%G]Rep Datafile: %Y#{qwknet.repdata}"
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
      when "/";  displaygroup(gpointer)
      when "B";  changebbsid(gpointer)
      when "Q";  gpointer = true
      when "NQ"; qwknetadd(gpointer)
      when "QN"; changeqwkname(gpointer)
      when "RD"; changerepdirectory(gpointer)
      when "RP"; changereppacket(gpointer)
      when "QD"; changeqwkdirectory(gpointer)
      when "QP"; changeqwkpacket(gpointer)
      when "QR"; qwknetremove(gpointer)
      when "QT"; changeqwktag(gpointer)
      when "QN"; changeqwkname(gpointer)
      when "QU"; changeqwklocalaccount(gpointer)
      when "FA"; changeftpaddress(gpointer)
      when "FC"; changeftpaccount(gpointer)
      when "FP"; changeftppassword(gpointer)
      when "A";  gpointer = addgroup
      when "W";  displaywho
      when "PU"; page
      when "N";  changegroupname(gpointer)
      when "D";  deletegroup(gpointer)
      when "G";  leave
      when "?";  gfileout ("groupmnu")
      end # of case
      p_return = [gpointer,(g_total - 1)]
    }
  end

  def change_group(number, prompt)
    group = fetch_group(number)
    qwknet = get_qwknet(group)
    if qwknet then
      new_val = getinp(prompt)
      if new_val == ""
        print "%RCancelled"
      else
        yield [qwknet, new_val]
      end
    else
      print "No QWK/NET Network defined."
    end
    displaygroup(number)
  end

  def changeftppassword(number)
    prompt = "%WEnter the FTP Password:%G  "
    change_group(number, prompt) do |qwknet, inp|
      ftppassword = inp

      if ftppassword.length > 40 then
        print "%RPassword too long. 40 Character Maximum"
      else
        qwknet.ftppassword = ftppassword
        update_qwknet(qwknet)
      end
    end
  end

  def changeftpaddress(number)
    prompt = "%WEnter the FTP Address:%G  "
    change_group(number, prompt) do |qwknet, inp|
      ftpaddress = inp

      if ftpaddress.length > 40 then
        print "%RAddress too long. 40 Character Maximum"
      else
        qwknet.ftpaddress = ftpaddress
        update_qwknet(qwknet)
      end
    end
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
    prompt = "%WEnter the FTP UserID:%G  "
    change_group(number, prompt) do |qwknet, inp|
      ftpaccount = inp

      if ftpaccount.length > 40 then
        print "%RUserID too long. 40 Character Maximum"
      else
        qwknet.ftpaccount = ftpaccount
        update_qwknet(qwknet)
      end
    end
  end

  def changeqwktag(number)
    prompt = "%WEnter the QWK  tag:%G  "
    change_group(number, prompt) do |qwknet, inp|
      qwktag = inp

      if qwktag.length > 78 then
        print "%RTag too long. 78 Character Maximum"
      else
        qwknet.qwktag =  convert_to_utf8(qwktag)
        update_qwknet(qwknet)
      end
    end
  end

  def changebbsid(number)
    prompt = "%WEnter the BBSID of the remote system:%G "
    change_group(number, prompt) do |qwknet, inp|
      bbsid = inp

      if bbsid.length > 40 then
        print "%RName too long. 40 Character Maximum"
      else
        bbsid.upcase!
        qwknet.bbsid = bbsid
        update_qwknet(qwknet)
      end
    end
  end

  def changeqwkdirectory(number)
    prompt = "%WEnter the path for QWK packets:%G "
    change_group(number, prompt) do |qwknet, inp|
      qwkdir = inp

      if qwkdir.length > 40 then
        print "%RPath too long. 40 Character Maximum"
      else
        qwknet.qwkdir = qwkdir
        update_qwknet(qwknet)
      end
    end
  end

  def changeqwkpacket(number)
    prompt = "%WEnter the file name for QWK packets:%G "
    change_group(number, prompt) do |qwknet, inp|
      qwkpacket = inp

      if qwkpacket.length > 40 then
        print "%RFilename too long. 40 Character Maximum"
      else
        qwknet.qwkpacket = qwkpacket
        update_qwknet(qwknet)
      end
    end
  end

  def changerepdirectory(number)
    prompt = "%WEnter the path for REP packets:%G "
    change_group(number, prompt) do |qwknet, inp|
      repdir = inp

      if repdir.length > 40 then
        print "%RPath too long. 40 Character Maximum"
      else
        qwknet.repdir = repdir
        update_qwknet(qwknet)
      end
    end
  end

  def changerepdata(number)
    prompt = "%WEnter the name for REP data packets:%G "
    change_group(number, prompt) do |qwknet, inp|
      repdata = inp

      if repdata.length > 40 then
        print "%RName too long. 40 Character Maximum"
      else
        qwknet.repdata = repdata
        update_qwknet(qwknet)
      end
    end
  end

  def changereppacket(number)
    prompt = "%WEnter the file name for REP packets:%G "
    change_group(number, prompt) do |qwknet, inp|
      reppacket = inp

      if reppacket.length > 40 then
        print "%RFilename too long. 40 Character Maximum"
      else
        qwknet.reppacket = reppacket
        update_qwknet(qwknet)
      end
    end
  end

  def changeqwkname(number)
    prompt = "%WEnter QWK/REP network name:%G "
    change_group(number, prompt) do |qwknet, inp|
      name = inp

      if name.length > 40 then
        print "%RName too long. 40 Character Maximum"
      else
        qwknet.name = name
        update_qwknet(qwknet)
      end
    end
  end

  def changeqwklocalaccount(number)
    prompt = "%WEnter the User ID of QWK/REP service account on the LOCAL system:%G "
    change_group(number, prompt) do |qwknet, inp|
      account = inp

      if account.length > 40 then
        print "%RAccount too long. 40 Character Maximum"
      else
        if !user_exists(account) then
          print "%RLocal user does not exist.  Try again..."
        else
          qwknet.qwkuser = account
          update_qwknet(qwknet)
        end
      end
    end
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
        prompt = "%WEnter the ftp account UserID on the REMOTE system:%G "
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

