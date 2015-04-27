class Session

  def scanformail # revised
    theme = get_user_theme(@c_user)
    i = 0
    ptr_check
    u = @c_user
    area = fetch_area(0)

    pointer = get_pointer(@c_user,0)
    new = new_email(pointer.lastread,u.name)

    if new > 0 then
      print theme.yes_mail_prompt.gsub("@new@","#{new}")
      return true
    end
    print theme.no_mail_prompt
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
    reademail(true) if yes(theme.yes_mail_readit, true, false,true)
  end


  def showemail(epointer)

    area = fetch_area(0)
    u = @c_user
    if (e_total(u.name) > 0) and (epointer > 0) then
			epointer = e_total(@c_user.name) if epointer > e_total(@c_user.name)
      displaymessage(epointer,area.number,true)
    else
      print "\r\n%Y;You have no email.  You have to send some to get some." if e_total(u.name) == 0
      print "\r\n%R;You haven't read any email yet." if epointer == 0
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
      o_prompt = "%M;[Email]%C; #{sdir} Read[#{epointer}] (1-#{e_total(u.name)}):%W; "
      inp = getinp(o_prompt)

      happy = inp.upcase
      if !happy.integer?
        #happy.gsub!(/[-\d]/,"")

      end

      case happy

      when ""
        if sdir == "+" then
          epointer = nextmail(epointer)
        else
          epointer = lastmail(epointer)
        end
      when "+"; sdir="+"; epointer = nextmail(epointer)
      when "-"; sdir="-"; epointer = lastmail(epointer)
      when "G"; leave
      when "R"
        if epointer > 0 then
          replyemail(epointer,0)
        else
          print "%WR;Nothing to reply to!%W;"
        end
      when "?"; write "%W;"; gfileout ("emailmnu")
      when "/";  showemail(epointer)
      when "QR"; display_qwk_routing_tables
      when "K"; deletemessage(epointer)
      when "N"; gfileout ("emailsnd");sendemail(false)
      when "S"; gfileout ("emailsnd");sendemail(false)
      when "Q"; break # exit input loop
      when /\d+/; epointer = jumpemail(happy.to_i,epointer,e_total(u.name)+1)
      else; print "%WR;Out of Range.%W;"
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
      displaymessage(epointer,area.number,true)
    else
      print "%WR;Out of Range%W;"
    end
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
      print("%WR; No More Email %W;")
    end
    return epointer
  end

  def lastmail(epointer) #revised

    ptr_check
    u = @c_user
    area = fetch_area(0)
    total = e_total(u.name)

    if epointer > 1 then
      epointer -=1
      displaymessage(epointer,area.tbl,true)
    else
      print("%WR; No More Email %W;")
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
      print "%WR; Email ##{epointer} [#{del}] deleted. %W;"
      ptr_check
    else
      print; print "%WR; No Messages %W;"
    end
  end



  # TODO: useless function - just use user_exists instead
  def findlocal(user)

    if user_exists(user) then
      return true
    else
      return false
    end
  end


  def display_qwk_routing_tables
    j = 0
    cont = true
    cols = %w(Y G C).map {|i| "%"+i +"%"}
    hcols = %w(WY WG WC).map {|i| "%"+i + "%"}
    headings = %w(Destination Route Last-Seen)
    widths = [15,40,20]
    header = hcols.zip(headings).map {|a,b| a+b}.formatrow(widths) + "%W%"
    underscore = cols.zip(['-'*30]*5).map{|a,b| a+b}.formatrow(widths)

    fetch_groups.each {|group| qwknet = get_qwknet(group)
      if !qwknet.nil? then

        if !get_qwkroutes(qwknet).nil? then
          print "#{qwknet.name}: #{get_qwkroutes(qwknet).length} routes found..."
          print header
          print underscore if !@c_user.ansi
          get_qwkroutes(qwknet).each {|route|
            t = route.modified.strftime("%m/%d/%y %I:%M%p")
            # TODO: get rid of all the "fix for 1.9" comments
            temp = cols.zip([route.dest,route.route,t]).map{|a,b| "#{a}#{b}"}.formatrow(widths) #fix for 1.9
            j +=1
            if j == (@c_user.length - 4) and @c_user.more then
              cont = moreprompt
              j = 1
              print
              print header
              print underscore if !@c_user.ansi
            end
            break if !cont
            print temp
          }
        end
        break if !cont
      end
    }

  end

  # TODO: why is this in Session? move to a library
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
      print "%RW;You do not have permission to send Email.%W;"
      return
    end
    print
    if !feedback then

      while true
        inp = getinp("%C;To:%W; ")
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
          area,path = qwk_route(route)
          if !area.nil? then
            print "Sending a QWK Netmail Message to: #{inp}"
          else
            print "%RW;No route to that host found.  Type %G;QR%R; for a list of known hosts.%W;"
            return
          end
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
          print "%WR;Local User not found...%W;"
        else
          to = inp
          m_type = LOCAL
          break
        end
      end

    else
      to = FEEDBACK_TO # because it's feedback.
      m_type = LOCAL
    end
    to.strip!
    title = getinp("%G;Title:%W; ")
    return false if title == ""
    reply_text = ["***No Message to Quote***"]
    # m_type = LOCAL
    if @c_user.fullscreen then
      write "%W;"
      msg_file = write_quote_msg([])
      launch_editor(msg_file)
      suck_in_text(msg_file)
      prompt = "Send email #{YESNO}"
      saveit = yes(prompt, true, false,true)
    else
      saveit,title = lineedit(:reply_text => reply_text,:title => title, :header =>"%G;Enter your Email.%Y;")
    end
    if saveit then

      system = fetch_system
      system.feedback_today += 1 if feedback
      system.emails_today += 1
      update_system(system)
      case m_type
      when LOCAL
        savecurmessage(0, to, :title => title)
        print "Sending Local e-mail..."

      when F_NETMAIL
        number = find_fido_area(NETMAIL)
        intl = "#{zone}:#{net}/#{node} #{FIDOZONE}:#{FIDONET}/#{FIDONODE}"
        savecurmessage(number, to, :title=>title, :destnode => node, :destnet => net, :intl => intl , :point => point)
        print "Sending Netmail..."

      when Q_NETMAIL
        group = fetch_group_grp(area.grp)
        qwknet = get_qwknet(group)
        bbsid = ""
        bbsid = qwknet.bbsid if !qwknet.nil?
        area = find_qwk_area(QWKMAIL,qwknet.grp)

        # area = find_qwk_area(QWKMAIL,nil)
        number = area.number
        if route.upcase != bbsid then
          @lineeditor.msgtext.unshift(inp)
          to = "NETMAIL"
        end
        savecurmessage(number,to,:title => title)
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
    pointer = get_pointer(@c_user,0)
    group = fetch_group_grp(area.grp)
    qwknet = get_qwknet(group)
    bbsid = ""
    bbsid = qwknet.bbsid if !qwknet.nil?
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
    if %w(R N).include?(pointer.access)
      print "%WR;You do not have write access.%W;"
      return false
    end
    m_type = LOCAL
    to = r_message.m_from.strip
    title = r_message.subject
    if r_message.f_network then
      happy = (/(.*) (.*)/) =~ r_message.intl
      r_intl = $2
			r_intl = "#{FIDOZONE}:#{r_message.orgnet}/#{r_message.orgnode}" if !happy
      print "Replying to: #{to} (#{r_intl})"
      zone,net,node,point = parse_intl(r_intl)
      if zone.nil? then
        zone = FIDOZONE
        net = r_message.orgnet
        node = r_message.orgnode
      end
      intl = "#{zone}:#{net}/#{node} #{FIDOZONE}:#{FIDONET}/#{FIDONODE}"
      m_type = F_NETMAIL
    end
    if r_message.network then
      out = bbsid
      out = r_message.q_via if ! r_message.q_via.nil?
      print "Replying to: %W;#{to}@#{out}"
      m_type = Q_NETMAIL
    end
    if r_message.smtp then
      m_type = SMTP
    end
    msg_text.unshift("--- #{to} wrote ---")
    for x in 0..msg_text.length - 1 do
      msg_text[x] = "> #{msg_text[x].chop!}"
    end
    print "%G;Title:%W; #{title}"
    prompt = "%C;Enter New Subject or #{RET}:%W; "
    tempstr = getinp(prompt) {|inp| inp.upcase == "CR" ? crerror : true }
    title = tempstr if tempstr != ""
    if @c_user.fullscreen then
      write "%W;"
      msg_file = write_quote_msg(msg_text)
      launch_editor(msg_file)
      suck_in_text(msg_file)
      print (CLS)
      prompt = "Send message #{YESNO}"
      saveit = yes(prompt, true, false,true)
    else
      saveit = lineedit(1,msg_text,false,title)
    end
    if saveit then
      system = fetch_system
      system.emails_today += 1
      update_system(system)
      case m_type
      when F_NETMAIL
        number = find_fido_area(NETMAIL)
        savecurmessage(number, to, :title => title,:destnode => node,:destnet => net,:intl => intl, :point => point)
        print "Sending Netmail..."
      when Q_NETMAIL
        area = find_qwk_area(QWKMAIL,qwknet.grp)
        if ! r_message.q_via.nil? then
          @lineeditor.msgtext.unshift("#{to}@#{ r_message.q_via}")
          to = "NETMAIL"

        end
        print "Sending QWK Netmail..."
        savecurmessage(area.number, to, :title => title,:destnode => node,:destnet => net ,:intl => intl,:point => point)
      when SMTP
        print "Sending SMTP (Internet) Email..."
        smtp_send(to,@c_user.name,title,@lineeditor.msgtext)
      when LOCAL
        savecurmessage(0, to, :title => title)
        print "Sending Local e-mail..."
      end
    end
  end


end

