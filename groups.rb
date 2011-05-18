class Session
  def displaygroup(number)
    group = fetch_group(number)
    write "\r\n%R;#%W;#{number} %G; #{group.groupname}"
    write "%R; [DELETED]" if group.delete
    print ""
    print "%C;QWK/REP Mapping:"
    print 
    if !get_qwknet(group).nil? then
      qwknet = get_qwknet(group)

      print " %G;[%Y;QN%G;]ame: %Y;#{qwknet.name}"
      print " %G;[%Y;QU%G;]Local QWK account: %Y;#{qwknet.qwkuser}"
      print " %G;[%Y;B%G;]BSid: %Y;#{qwknet.bbsid}"
      print " %G;[%Y;RD%G;]Rep Directory: %Y;#{qwknet.repdir}"
      print " %G;[%Y;RP%G;]Rep Packet: %Y;#{qwknet.reppacket}"
      print " %G;[%Y;RP%G;]Rep Datafile: %Y;#{qwknet.repdata}"
      print " %G;[%Y;QP%G;]QWK Directory: %Y;#{qwknet.qwkdir}"
      print " %G;[%Y;QP%G;]QWK Packet: %Y;#{qwknet.qwkpacket}"
      print " %G;[%Y;QT%G;]QWK Tag:"
      print "  %Y;#{qwknet.qwktag}"
      print " %G;[%Y;FA%G;]FTP Address: %Y;#{qwknet.ftpaddress}"
      print " %G;[%Y;FC%G;]FTP User: %Y;#{qwknet.ftpaccount}"
      print " %G;[%Y;FP%G;]FTP Password: %Y;#{qwknet.ftppassword}"
      print " %G;[%Y;?%G;]More Options"
      print
    else
      print " %WR; No QWK network assigned.%W;"
    end
  end #displaygroup

  def groupmaintmenu
    readmenu(
      :initval => 0,
      :range => 0..(g_total - 1),
    :loc => GROUP
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
      print "%WR; No QWK/NET Network defined. %W;"
    end
    displaygroup(number)
  end

  def changeftppassword(number)
    prompt = "%W;Enter the FTP Password:%G;  "
    change_group(number, prompt) do |qwknet, inp|
      ftppassword = inp

      if ftppassword.length > 40 then
        print "%%WR; Password too long. 40 Character Maximum %W;"
      else
        qwknet.ftppassword = ftppassword
        update_qwknet(qwknet)
      end
    end
  end

  def changeftpaddress(number)
    prompt = "%W;Enter the FTP Address:%G;  "
    change_group(number, prompt) do |qwknet, inp|
      ftpaddress = inp

      if ftpaddress.length > 40 then
        print "%WR; Address too long. 40 Character Maximum%W;"
      else
        qwknet.ftpaddress = ftpaddress
        update_qwknet(qwknet)
      end
    end
  end

  def qwknetremove(number)
    group = fetch_group(number)

    if  get_qwknet(group).nil? then
      print "%WR; No QWK network to delete %W;"
    else
      print "%WR; WARNING: %YThis action is permenent and may cause damage.%W;"
      commit = yes("Are you sure #{YESNO}",true,false,true)
      if commit then
        remove_qwknet(group)
      else
        print "Cancelled."
      end
    end
  end 

  def changeftpaccount(number)
    prompt = "%W;Enter the FTP UserID:%G;  "
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
        print "%WR; Tag too long. 78 Character Maximum %W;"
      else
        qwknet.qwktag =  convert_to_utf8(qwktag)
        update_qwknet(qwknet)
      end
    end
  end

  def changebbsid(number)
    prompt = "%W;Enter the BBSID of the remote system:%G; "
    change_group(number, prompt) do |qwknet, inp|
      bbsid = inp

      if bbsid.length > 40 then
        print "%WR; Name too long. 40 Character Maximum %W;"
      else
        bbsid.upcase!
        qwknet.bbsid = bbsid
        update_qwknet(qwknet)
      end
    end
  end

  def changeqwkdirectory(number)
    prompt = "%W;Enter the path for QWK packets:%G; "
    change_group(number, prompt) do |qwknet, inp|
      qwkdir = inp

      if qwkdir.length > 40 then
        print "%WR; Path too long. 40 Character Maximum %W;"
      else
        qwknet.qwkdir = qwkdir
        update_qwknet(qwknet)
      end
    end
  end

  def changeqwkpacket(number)
    prompt = "%W;Enter the file name for QWK packets:%G; "
    change_group(number, prompt) do |qwknet, inp|
      qwkpacket = inp

      if qwkpacket.length > 40 then
        print "%WR; Filename too long. 40 Character Maximum %W;"
      else
        qwknet.qwkpacket = qwkpacket
        update_qwknet(qwknet)
      end
    end
  end

  def changerepdirectory(number)
    prompt = "%W;Enter the path for REP packets:%G; "
    change_group(number, prompt) do |qwknet, inp|
      repdir = inp

      if repdir.length > 40 then
        print "%WR; Path too long. 40 Character Maximum %W;"
      else
        qwknet.repdir = repdir
        update_qwknet(qwknet)
      end
    end
  end

  def changerepdata(number)
    prompt = "%W;Enter the name for REP data packets:%G; "
    change_group(number, prompt) do |qwknet, inp|
      repdata = inp

      if repdata.length > 40 then
        print "%WR; Name too long. 40 Character Maximum %W;"
      else
        qwknet.repdata = repdata
        update_qwknet(qwknet)
      end
    end
  end

  def changereppacket(number)
    prompt = "%W;Enter the file name for REP packets:%G; "
    change_group(number, prompt) do |qwknet, inp|
      reppacket = inp

      if reppacket.length > 40 then
        print "%WR; Filename too long. 40 Character Maximum %W;"
      else
        qwknet.reppacket = reppacket
        update_qwknet(qwknet)
      end
    end
  end

  def changeqwkname(number)
    prompt = "%W;Enter QWK/REP network name:%G; "
    change_group(number, prompt) do |qwknet, inp|
      name = inp

      if name.length > 40 then
        print "%WR; Name too long. 40 Character Maximum %W;"
      else
        qwknet.name = name
        update_qwknet(qwknet)
      end
    end
  end

  def changeqwklocalaccount(number)
    prompt = "%W;Enter the User ID of QWK/REP service account on the LOCAL system:%G; "
    change_group(number, prompt) do |qwknet, inp|
      account = inp

      if account.length > 40 then
        print "%WR; Account too long. 40 Character Maximum %W;"
      else
        if !user_exists(account) then
          print "%WR; Local user does not exist.  Try again... %W;"
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
        prompt = "%W;Enter QWK/REP network name:%G "
        name = getinp(prompt)
        if name == "" then
          print "%WR; Cancelled %W;"
          return [gpointer,(g_total - 1)]
        end
        if name.length > 40 then
          print "%WR; Name too long. 40 Character Maximum %W;"
        else break end
      end

      while true
        prompt = "%W;Enter the BBSID of the remote system:%G; "
        bbsid = getinp(prompt) {|n| n != ""}
        if bbsid.length > 40 then
          print "%WR; Name too long. 40 Character Maximum %W;"
        else break end
      end

      while true
        prompt = "%W;Enter the User ID of QWK/REP service account on the LOCAL system:%G; "
        qwkuser = getinp(prompt) {|n| n != ""}
        if qwkuser.length > 40 then
          print "%WR; Name too long. 40 Character Maximum %W;"
        else
          if !user_exists(qwkuser) then
            print "%WR; Local user does not exist.  Try again... %W;"
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
        prompt = "%W;Enter the ftp account UserID on the REMOTE system:%G; "
        ftpaddress = getinp(prompt) {|n| n != ""}
        if ftpaddress.length > 40 then
          print "%WR; Name too long. 40 Character Maximum %W:"
        else break end
      end

      while true
        prompt = "%W;Enter the ftp account password on the REMOTE system:%G; "
        ftppassword = getinp(prompt) {|n| n != ""}
        if ftppassword.length > 40 then
          print "%WR; Name too long. 40 Character Maximum %W;"
        else break end
      end

      commit = yes("Are you sure #{YESNO}",true,false,true)
      if commit then
        add_qwknet(group,name,bbsid,qwkuser,ftpaddress,ftpaccount,ftppassword)
      else
        print "%WR; Cancelled. %W;"
        return
      end
    else
      print "%WR; You may only have one QWK network per message group. %W;"
    end
  end

  def deletegroup(gpointer)
    if gpointer <= 1
      print "%WR; You cannot delete group 0 or 1. %W;"
      return
    end

    group = fetch_area(gpointer)

    if group.delete
      area.delete = false
      print "%WG; Group ##{gpointer} UNdeleted %W;"
    else
      group.delete = true
      print "%WR; Group ##{gpointer} deleted. %W;"
    end
    update_group(group)
  end


  def addgroup
    while true
      prompt = "Enter new group name: "
      name = getinp(prompt) 
      if name == "" then
        print "%WR; Cancelled %W;"
        return
      end
      if name.length > 40 then
        print "%WR; Name too long. 40 Character Maximum %W;"
      else break end
    end

    commit = yes("Are you sure #{YESNO}",true,false,true)
    if commit then
      add_group(name)
      gpointer = g_total - 1
    else
      print "%WR; Cancelled. %W;"
      gpointer = g_total - 1
      return
    end
  end

  def changegroupname(gpointer)
    group = fetch_group(gpointer)

    prompt = "Enter new group name: "
    name = getinp(prompt) 
    if name == "" then
      print "%WR; Cancelled %W;" 
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

