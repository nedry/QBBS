class Session

  def scanformail # revised
    i = 0
    ptr_check
    u = @c_user
    area = fetch_area(0)
    print; write "Scanning for New Email... "
    pointer = get_pointer(@c_user,0)
    new = new_email(pointer.lastread,u.name)

    if new > 0 then
     m = "message"
     m = "messages" if new > 1
        print "%G#{new} new #{m} found."
        return true
    end
     print "none."
     return false
   end

  def ptr_check
    area = fetch_area(0)
    pointer = get_pointer(@c_user,0)
    if pointer.nil? then 
     add_pointer(@c_user,0,"I",0)
    end
    total = e_total(@c_user.name) # changed for new message format
    update_user(@c_user)
  end

  def readitnow
    reademail(true) if yes(CRLF+"Read them now #{YESNO}", true, false,true)
  end


 def showemail(epointer)

    area = fetch_area(0)
    u = @c_user
    if (e_total(u.name) > 0) and (epointer > 0) then
      displaymessage(epointer,area.number,true)
    else
      print "\r\n%YYou have no email.  You have to send some to get some." if e_total(u.name) == 0
      print "\r\n%RYou haven't read any email yet." if epointer == 0
    end
  end
  
  def emailmenu #revised
    @who.user(@c_user.name).where="Email Menu"
    update_who_t(@c_user.name,"Email Menu")
    out = "Read"
    sdir="+"
    area = fetch_area(0)
    ptr_check
    u = @c_user
    p_area = @c_area
    @c_area = 0
    pointer = get_pointer(@c_user,0)
    epointer = e_total(u.name) - new_email(pointer.lastread,u.name)

    done = false

    while true
      o_prompt = "%M[Email]%C #{sdir} Read[#{epointer}] (1-#{e_total(u.name)}): "
      inp = getinp(o_prompt)

      happy = inp.upcase
      if !happy.integer?
        #happy.gsub!(/[-\d]/,"")

      end

      case happy

      when ""; if sdir == "+" then epointer = nextmail(epointer) else epointer = lastmail(epointer) end
      when "+"; sdir="+"; epointer = nextmail(epointer)
      when "-"; sdir="-"; epointer = lastmail(epointer)
      when "G"; leave
      when "R"; if epointer > 0 then replyemail(epointer,0)  else print "%RNothing to reply to!" end
      when "?"; write "%W"; gfileout ("emailmnu")
      when "/";  showemail(epointer)
   
      when "K"; deletemessage(epointer)
      when "N"; gfileout ("emailsnd");sendemail(false)
      when "S"; gfileout ("emailsnd");sendemail(false)
      when "Q"; break # exit input loop
      when /\d+/; epointer = jumpemail(happy.to_i,epointer,e_total(u.name)+1)
    else; print "Out of Range."
    end #of case
    done
  end
  @c_area = p_area

end

def jumpemail(inp,epointer,max) #revised
  ptr_check
  u = @c_user
  area = fetch_area(0)
  total = e_total(u.name)

  if inp > 0 and inp < max and total > 0 then
    epointer = inp
    puts "epointer: #{epointer}"
    displaymessage(epointer,area.number,true)
  else print "%ROut of Range" end
  epointer
end

def nextmail(epointer) #revised

  ptr_check
  u = @c_user
  area = fetch_area(0)
  total = e_total(u.name)

  if epointer < total and total > 0 then
    epointer +=1
    displaymessage(epointer,area.number,true)
  else
    print("%RNo More Email")
  end
  return epointer
end

def lastmail(epointer) #revised

  ptr_check
  u = @c_user
  area = fetch_area(0)
  total = e_total(area.tbl,u.name)

  if epointer > 1 then
    epointer -=1
    displaymessage(epointer,area.tbl,true)
  else
    print("%RNo More Email")
  end
  return epointer
end


def deletemessage(epointer) #revised

  u = @c_user
  area = fetch_area(0)
  total = e_total(u.name)
  del = email_absolute_message(epointer,u.name)

  if total > 0 then
    delete_msg(del)
    print "Email ##{epointer} [#{del}] deleted."
    ptr_check
  else
    print; print "No Messages"
  end
end



def findlocal(user)

  if user_exists(user) then
    return true
  else
    return false
  end
end

def smtp_send(to,from,subject,message)
  msgstr = message.join("\n")
  from_smtp = "#{from.gsub(" ",".")}@#{SMTPDOMAIN}"
  msg = [ "From: #{from_smtp}\n","To: #{to}\n","Subject: #{subject}\n", "\n", "#{msgstr}" ]
  Net::SMTP.start(SMTPSERVER, 25) do |smtp|
    smtp.send_message msg, from_smtp, to
  end
end

def sendemail(feedback)

  to = nil;zone = nil;net = nil;node = nil;point = nil
  pointer = get_pointer(@c_user,0)
  if pointer.access =~ /[RN]/
    print "%RYou do not have permission to send Email."
    return
  end
  print
  if !feedback then

    while true
      inp = getinp("%CTo: ")
      to,zone,net,node,point = netmailadr(inp)
      return if inp == ""
      if !to.nil? then
        print "Sending a Netmail Message to: #{inp}"
        m_type = F_NETMAIL
        to.upcase!
        break
      end
      to,route = qwkmailadr(inp)
      if !to.nil? then
        print "Sending a QWK Netmail Message to: #{inp}"
        m_type = Q_NETMAIL
        to.upcase!
        break
      end
      smtp = stmpmailadr(inp)
      if smtp then
        print "Sending a SMTP (Internet Email) Message to: #{inp}"
        to = inp
        m_type = SMTP
        break
      end
      if !findlocal(inp) then
        print "%RLocal User not found..."
      else
        to = inp
        m_type = LOCAL
        break
      end
    end

  else
    to = SYSOPNAME # because it's feedback.
  end
  to.strip!
  title = getinp("%GTitle: ")
  return false if title == ""
  reply_text = ["***No Message to Quote***"]
  # m_type = LOCAL
  if @c_user.fullscreen then
    write "%W"
    msg_file = write_quote_msg("")
    launch_editor(msg_file)
    suck_in_text(msg_file)
    prompt = "Send email #{YESNO}"
    saveit = yes(prompt, true, false,true)
  else
    saveit = lineedit(1,reply_text)
    puts saveit
    puts "m_type=#{m_type}"
  end
  if saveit then
    case m_type
    when LOCAL
      savecurmessage(0,to, title, false,false,nil,nil,nil,nil)
      print "Sending Local e-mail..."

    when F_NETMAIL
      table,number = find_fido_area(NETMAIL)
      intl = "#{zone}:#{net}/#{node} #{FIDOZONE}:#{FIDONET}/#{FIDONODE}"
      savecurmessage(to,title,false,false,node,net,intl,point,number)
      print "Sending Netmail..."

    when Q_NETMAIL
      area = find_qwk_area(QWKMAIL,nil)
      number = area.number
      if route.upcase != BBSID then
        @lineeditor.msgtext.unshift(inp)
        to = "NETMAIL"
      end
      savecurmessage(number,to,title,false,false,nil,nil,nil,nil)
      print "Sending QWK Netmail..."
    when SMTP
      print "Sending SMTP (Internet) Email..."
      smtp_send(to,@c_user.name,title,@lineeditor.msgtext)
      #send_smtp

    end #of case
  end
end # of def sendemail

def replyemail(epointer,carea)
  area = fetch_area(carea)
  u = @c_user
  if carea > 0 then
    abs = absolute_message(area.number,epointer)
    r_message = fetch_msg(abs)
  else
    r_message = fetch_msg(email_absolute_message(epointer,u.name) )
  end
  msg_text = []
  r_message.msg_text.each_line(DLIM) {|line| msg_text.push(line.chop!)} #1.9 modification
  done = false
  print
  if %w(R N).include?(@c_user.areaaccess[0])
    print "%RYou do not have write access."
    return false
  end
  m_type = LOCAL
  to = r_message.m_from.strip
  title = r_message.subject
  if r_message.f_network then
    happy = (/(.*) (.*)/) =~ r_message.intl
    r_intl = $2
    print "Replying to: #{to} (#{r_intl})"
    zone,net,node,point = parse_intl(r_intl)
    if zone.nil? then
      zone = FIDOZONE
      net = r_message.orgnet
      node = r_message.orgzone
    end
    intl = "#{zone}:#{net}/#{node} #{FIDOZONE}:#{FIDONET}/#{FIDONODE}"
    m_type = F_NETMAIL
  end
  if r_message.network then
    msg_text,msgid,via,tz,reply = qwk_kludge_search(msg_text)
    out = BBSID
    out = via if !via.nil?
    print "Replying to: %W#{to}@#{out}"
    m_type = Q_NETMAIL
  end
  if r_message.smtp then
    m_type = SMTP
  end
  msg_text.unshift("--- #{to} wrote ---")
  for x in 0..msg_text.length - 1 do
    msg_text[x] = "> #{msg_text[x].chop!}"
  end
  print "%GTitle: #{title}"
  prompt = "%REnter New Subject or %W %Y<--^%W: "
  tempstr = getinp(prompt) {|inp| inp.upcase == "CR" ? crerror : true }
  title = tempstr if tempstr != ""
  if @c_user.fullscreen then
    write "%W"
    msg_file = write_quote_msg(msg_text)
    launch_editor(msg_file)
    suck_in_text(msg_file)
    print (CLS)
    prompt = "Send message #{YESNO}"
    saveit = yes(prompt, true, false,true)
  else
    saveit = lineedit(1,msg_text)
  end
  if saveit then
    case m_type
    when F_NETMAIL
      table,number = find_fido_area(NETMAIL)
      savecurmessage(number, to, title, false,false,node,net,intl,point)
      print "Sending Netmail..."
    when Q_NETMAIL
      number = find_qwk_area(QWKMAIL,nil)
      if !via.nil? then
        @lineeditor.msgtext.unshift("#{to}@#{via}")
        to = "NETMAIL"

      end
      print "Sending QWK Netmail..."
      savecurmessage(number, to, title, false,false,node,net,intl,point)
    when SMTP
      print "Sending SMTP (Internet) Email..."
      smtp_send(to,@c_user.name,title,@lineeditor.msgtext)
    when LOCAL
      savecurmessage(0, to, title, false,false,nil,nil,nil,nil)
      print "Sending Local e-mail..."
    end
  end
end


end

