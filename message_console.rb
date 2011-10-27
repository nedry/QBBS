require 'db/db_groups'
require 'db/db_message'
require 'db/db_email'
require 'errors'
require 'tools'
require 'doors'
require 'email'

class MessageConsole < Console
  def messagemenu(zipread)
    scanforaccess(@session.c_user)
    @session.who.user(@session.c_user.name).where="Message Menu"
    update_who_t(@session.c_user.name,"Reading Messages")
    out = "Read"
    if zipread then
      out = "ZIPread"
      return if !zipscan(1)
    end
    readmenu(
      :out => out,
      :initval => p_msg,
      :range => 1..h_msg,
      :prompt => '"%M[Area #{@session.c_area}]%C #{sdir} #{out}[%p] '+
      '(1-#{h_msg}): "'
    ) {|sel, mpointer, moved, out|

      mpointer = h_msg if mpointer.nil?
      mpointer = h_msg if mpointer > h_msg

      if !sel.integer?
        parameters = Parse.parse(sel)
        sel.gsub!(/[-\d]/,"")
      end

      if moved
        if (mpointer > 0) and (mpointer <= h_msg) then # range check
          show_message(mpointer)
        end
      end

      case sel
      when "E"; emailmenu
      when "/"; show_message(mpointer)
      when "PU"; page
      when "K"; kill_message(mpointer)
      when "Q"; mpointer = true # passing back true tells the other block to exit
      when "G"; leave
      when "P"; post
      when "W"; displaywho
      when "R"; reply_to_message(mpointer)
      when "FH"; display_fido_header(mpointer)
      when "A"; mpointer = area_change(parameters)
      when "MK"; mass_kill(parameters)
      when "?"; gfileout ("readmnu")
      end
      p_return = [mpointer,h_msg,out] # evaluate so this is the value that is returned
    }
  end

  def select_message_group
    groups = fetch_groups
    print "%GMessage Groups:"
    groups.each_with_index {|group, j| print "#{j}: #{group.groupname}"}
    print
    prompt = "Which, or %Y<--^ for all: "
    selected = getnum(prompt2,-1,groups.length - 1)
    return selected ? groups[selected].grp : nil
  end

  def display_header
    print "%W# %GNew %RAccess %YGroup %BBoard Description"
    print "%W-- %G---- %R------ %Y----- %B-----------------"
  end

  def display_new_message(area, pointer)
    l_read = new_messages(area.number, pointer.lastread)

    print "%W#{area.number.to_s.ljust(5)} " +
      "%G#{l_read.to_s.rjust(4)} " +
      "%R#{pointer.access_display.ljust(8)}" +
      "%Y#{area.group.groupname.ljust(10)}" +
      "%B#{area.name}"
  end

  def display_message(mpointer, table, email)
    if mpointer == 0 then
      print "%ROut of Range"
      return
    end

    i = 0
    area = fetch_area(@session.c_area)
    pointer = get_pointer(@session.c_user,area.number)
    u = @session.c_user

    abs = email ?
      email_absolute_message(mpointer, u.name) :
      absolute_message(table, mpointer)

    curmessage = fetch_msg(abs)

    if pointer.lastread < curmessage.absolute then
      pointer.lastread = curmessage.absolute
      update_pointer(pointer)
    end

    message = []
    tempmsg = convert_to_ascii(curmessage.msg_text)
    if curmessage.network then
      tempmsg, kludge= qwk_kludge_search(tempmsg)
    end

    tempmsg.each_line(DLIM) {|line| message.push(line.chop!)} #changed from .each for ruby 1.9

    write "%W##{mpointer} %G[%C#{curmessage.absolute}%G] %M#{curmessage.msg_date.strftime("%A the %d#{time_thingie(curmessage.msg_date)} of %B, %Y  %I:%M%p")}"
    if kludge.tz then
      tz = kludge.tz.upcase
      out = TIME_TABLE[kludge.tz] || non_standard_zone(tz)
      write " %W(%G#{out}%W)"
    end
    write "%G [NETWORK MESSAGE]" if curmessage.network
    write "%G [SMTP]" if curmessage.smtp
    write "%G [FIDONET MESSAGE]" if curmessage.f_network
    write "%Y [EXPORTED]" if curmessage.exported and !curmessage.f_network and !curmessage.network
    write "%B [REPLY]" if curmessage.reply
    print ""
    print "%CTo: %G#{curmessage.m_to}"
    write "%CFrom: %G#{curmessage.m_from.strip}"
    if curmessage.f_network then
      out = "UNKNOWN"
      if curmessage.intl then
        if curmessage.intl.length > 1 then
          o_adr = curmessage.intl.split[1]
          zone,net,node,point = parse_intl(o_adr)
          out = "#{zone}:#{net}/#{node}"
          out << ".#{point}" if point
        end
      else
        out = get_orig_address(curmessage.msgid)
      end
      write " %G(%C#{out}%G)"
    end
    if curmessage.network then
      out = kludge.via || BBSID
      write " %G(%C#{out}%G)"
    end
    print
    print "%CTitle: %G#{curmessage.subject}%Y"

    j = 5
    cont = true

    message.each {|line|
      j += 1
      write line
      if j == u.length - 2 and u.more then
        print
        cont = moreprompt
        j = 1
        break if !cont
      else
        print
      end
    }
    print
  end #displaymesasge

  def reply(mpointer)
    priv = false
    print
    user = @session.c_user
    area = fetch_area(@session.c_area)
    pointer = get_pointer(@session.c_user, @session.c_area)

    if pointer.access !~ /[RN]/
      abs = absolute_message(area.number, mpointer)
      r_message = fetch_msg(abs)
      to = r_message.m_from
      to.strip! if r_message.network #strip for qwk/rep but not for fido. Why?
      while true
        prompt = "%Gpriv (y,N,x - abort)? "
        reptype = getinp(prompt).upcase
        if (r_message.network or r_message.f_network) and reptype == "Y"
          replyemail(mpointer,@c_area)
          return
        else
          break
        end
      end

      case reptype
      when "Y"; priv = true
      when "X"; return
      end

      title = r_message.subject

      print "%GTitle: #{title}"
      title = get_or_cr("%REnter Title (<CR> for old): ", title)
      reply_text = [">--- #{to} wrote ---"]
      r_message.msg_text.each_line(DLIM) {|line|
        reply_text.push("> #{line.chop!}")
      }

      saveit = edit_msg(reply_text, quote = true)
      if (saveit) then
        x = priv ? 0 : @session.c_area
        savecurmessage(x, to, title, false, true, nil, nil, nil, nil)
        print priv ? "Sending priv Mail..." : "%GSaving Message.."
      else
        print "%RMessage Cancelled."
      end
    end
  end

  def savecurmessage(x, to, title, exported, reply, destnode, destnet, intl, point)
    area = fetch_area(x)
    @session.lineeditor.msgtext << DLIM
    msg_text = @session.lineeditor.msgtext.join(DLIM)
    m_from = @session.c_user.name
    msg_date = Time.now.strftime("%Y-%m-%d %I:%M%p")
    absolute = add_msg(to,m_from,msg_date,title,msg_text,exported,false,destnode,destnet,intl,point,false, nil,nil,nil,
                       nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,reply,area.number)
    add_log_entry(5,Time.now,"#{@c_user.name} posted msg # #{absolute}")
  end

  def write_quote_msg(reply_text)
    num = rand(100000).to_s
    outfile = "msg#{num}"
    path = "#{FULLSCREENDIR}/#{outfile}"
    quotefile = File.new(path, File::CREAT|File::APPEND|File::RDWR, 0666)
    quotefile.puts "#{CRLF}"
    reply_text.each {|line| quotefile.puts "#{line.chop![0..75]}#{CRLF}"} if reply_text != nil
    quotefile.close
    return outfile
  end

  def suck_in_text(msg_file)
    ledit = @session.lineeditor
    ledit.msgtext = []
    if File.exists?("#{FULLSCREENDIR}/#{msg_file}")
      IO.foreach("#{FULLSCREENDIR}/#{msg_file}") { |line| ledit.msgtext.push(line.chomp!) }
    end
    system("rm #{FULLSCREENDIR}/#{msg_file}")
    return true
  end

  def launch_editor(msg_file)
    launch = FULLSCREENPROG
    launch.gsub!("%a",FULLSCREENDIR)
    print (CLS)
    print (HOME)
    sleep(1)
    puts "launch: #{launch}"
    puts "msg_file: #{msg_file}"
    puts "fullscreendir: #{FULLSCREENDIR}"

    puts "string: #{launch} #{FULLSCREENDIR}/#{msg_file}"
    door_do("#{launch} #{FULLSCREENDIR}/#{msg_file}","")
    print (CLS)
    print (HOME)
  end

  def post
    scanforaccess(@session.c_user)
    done = false
    area = fetch_area(@session.c_area)
    pointer = get_pointer(@session.c_user, area.number)

    if pointer.access[@session.c_area] =~ /[RN]/
      print "%RYou do not have write access."
      return
    end

    print
    to = get_or_cr("%CTo (<CR> for All): ", "ALL")
    prompt = "%GTitle: "
    title = getinp(prompt)
    return if title == ""
    reply_text = ["***No Message to Quote***"]

    saveit = edit_msg(reply_text, quote = false)
    if saveit then
      savecurmessage(@session.c_area, to, title,false,false,nil,nil,nil,nil)
      @session.c_user.posted += 1
      update_user(@session.c_user)
    end
  end # of def post

  def edit_msg(reply_text)
    if @session.c_user.fullscreen then
      write "%W"
      msg_file = write_quote_msg(nil)
      launch_editor(msg_file)
      suck_in_text(msg_file)
      prompt = "Post message #{YESNO}"
      saveit = yes(prompt, true, false,true)
    else
      saveit = lineedit(1,reply_text,false)
    end
  end

  def display_fido_header(mpointer)
    area = fetch_area(@c_area)
    if (h_msg > 0) and (mpointer > 0) then
      u = @c_user
      fidomessage = fetch_msg(absolute_message(@c_area,mpointer))
      print
      print "%COrg:%G #{fidomessage.orgnet}/#{fidomessage.orgnode}"
      print "%CDest:%G #{fidomessage.destnet}/#{fidomessage.destnode}"

      # [[field, attr], ....]. if attr is missing, it is field.downcase
      fields = [ "Attribute", "Cost", ["Date Time", :msg_date], ["To", :m_to],
        ["From", :m_from], "Subject", "Area", "Msgid", "Path", ["TzUTZ", :tzutc],
        "CharSet", ["Tosser ID", :tid], ["Proc ID", :pid], "Intl", "Topt", "Fmpt",
        "Reply", "Origin"]

      fields.each do |f|
        field, attr = (f.is_a? Array) ? f : [f, f.downcase]
        val = fidomessage.send(attr)
        print "%C#{field}:%G #{val}" if val
      end

      print
    else
      no_message(mpointer)
    end
  end

  def non_standard_zone(inzone)
    inzone = inzone[4..7] if inzone.length == 7
    num = inzone.to_i(16)
    minutes_utc = num - 65536
    if minutes_utc > -720 and minutes_utc < 720 then
      hours_utc = minutes_utc / 60.0
      rem_h = hours_utc.ceil
      remainder = minutes_utc - (hours_utc.ceil * 60)
      t_remainder = remainder.abs.to_s
      t_remainder << "0" if t_remainder.length < 2
      return "#{rem_h}:#{t_remainder} UTC"
    else
      return "UNKNOWN"
    end
  end

  def h_msg
    area = fetch_area(@session.c_area)
    h_msg = m_total(area.number)
  end

  def p_msg
    user = @session.c_user
    area = fetch_area(@session.c_area)
    pointer = get_pointer(@session.c_user,area.number)
    p_msg = m_total(area.number) - new_messages(area.number,pointer.lastread) # modified for db change
  end

  def zipscan(start)
    scanforaccess(@session.c_user)
    a_list = fetch_area_list(nil)
    start = find_current_area(a_list, @session.c_area)

    for i in start..(a_total - 1)
      #area = fetch_area(i)
      pointer = get_pointer(@session.c_user,i)
      l_read = new_messages(a_list[i].number,pointer.lastread)
      t = pointer.access
      if l_read > 0 then
        if pointer.zipread and (t !~ /[NI]/ or @session.c_user.level == 255) and (!a_list[i].delete) then
          @session.c_area = a_list[i].number
          print "%GChanging to the #{a_list[i].group}: #{a_list[i].name} sub-board"+CRLF
          mpointer = p_msg
          sleep (0.5)
          mpointer = h_msg if mpointer > h_msg
          return mpointer
        end
      end
    end
    print "No more messages"
    return nil
  end

  def kill_message(mpointer)
    if mpointer > 0 then
      area = fetch_area(@session.c_area)
      abs = absolute_message(area.number,mpointer) #modified for db change
      d_msg = fetch_msg(abs) #modified for db change

      if d_msg.locked == true then
        print CRLF + "%RCannot Delete. Message Locked."
        return
      end

      u = @session.c_user
      if !((u.areaaccess[@session.c_area] =~ /[CM]/) or (u.level == 255)) then
        print CANNOTKILLMESSAGESERROR
        return
      end

      if h_msg > 0
        delete_msg(abs)
        print "%RMessage ##{mpointer} [#{abs}] deleted."
      else
        print CRLF+"%RNo Messages"
      end
    else
      print CRLF+"%RYou can't delete message 0, because it doesn't exist!"
    end
  end

  def mass_kill(parameters)
    area = fetch_area(@session.c_area)
    start, stop = parameters[0..1]
    pointer = get_pointer(@session.c_user, @session.c_area)

    if (start < 1) or (start > h_msg) or (stop < 1) or (stop > h_msg) then
      print "%ROut of Range dude!"
      return
    end

    if !((pointer.access =~ /[CM]/) or (@c_user.level == 255) ) then
      print CANNOTKILLMESSAGESERROR
      return
    end

    first = absolute_message(area.number,start)  #this need rewriting for the new db format
    last = absolute_message(area.number,stop)
    prompt = "%RDelete messages #{start} to #{stop} #{YESNO}"
    delete_msgs(area.number,first,last) if yes(prompt, true, false,true)
  end

  def reply_to_message(mpointer)
    if mpointer > 0 then
      reply(mpointer)
    else
      print "%GYou haven't read a message yet."
    end
  end

  def show_message(mpointer)
    area = fetch_area(@session.c_area)
    if (h_msg > 0) and (mpointer > 0) then
      display_message(mpointer,area.number,false)
    else
      no_message(mpointer)
    end
  end

  def no_message(mpointer)
    print "\r\n%YThis message area is empty. Why not %G[P]ost%Y a Message?" if h_msg == 0
    print "\r\n%RYou haven't read any messages yet." if mpointer == 0
  end

  # change current area
  def area_change(parameters)
    tempint = -1
    scanforaccess(@c_user)

    if (parameters[0] > -1) then
      tempint = parameters[0]
    else
      tempint = displaylist
      tempint = -1 if !tempint.kind_of?(Fixnum)
    end

    while true
      if tempint == - 1 then
        prompt = CRLF+"%WArea #[#{@c_area}] (1-#{(a_total - 1)}) ? %Y<--^%W to quit: "
        happy = getinp(prompt).upcase
        tempint = happy.to_i
      end

      case happy
      when ""; break
      when "CR"; crerror; tempint = -1
      when "?"
        tempint = displaylist
        tempint = -1 if !tempint.kind_of?(Fixnum)
        #else
      end
      if (0..(a_total - 1)).include?(tempint)
        pointer = get_pointer(@c_user,tempint)
        t = pointer.access
        area = fetch_area(tempint)
        if t !~ /[NI]/ or (@c_user.level == 255) and (!area.delete)
          @c_area = tempint
          print "%GChanging to #{area.group.groupname}: #{area.name} area"+CRLF
          break
        else
          if t == "N" then
            print "%RYou do not have access"
          else
            print "%RThat area does not exist."
          end
          break
          tempint = -1
        end # of if
      else tempint = -1
      end #of if in range
      #end #of case
    end # of while true
    mpointer = p_msg
    mpointer = h_msg if mpointer > h_msg
    #puts "area change m_pointer: #{mpointer}"
    return mpointer
  end # of def

  def find_current_area(a_list,num)
    result, _ = a_list.each_with_index.find {|list, i|
      list.number == num
    }
    return result
  end
end
