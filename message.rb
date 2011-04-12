require 'tools.rb'
require 'messagestrings.rb'
require 'menu.rb'
require 'doors.rb'
require 'encodings.rb'

class Session


  def displaylist
    cont = false
    user = @c_user
    more = 0
    groups = fetch_groups
    prompt = "%W;More #{YESNO} or Area #? "
    prompt2 = "Which, or #{RET} for all: "
    print
    print "%G;Message Groups:"
    groups.each_index {|j| print "#{j}: #{groups[j].groupname}"}
    print
    tempint = getnum(prompt2,-1,groups.length - 1)
    print
    cols = %w(B C R Y G).map {|i| "%"+i +";"}
    hcols = %w(WB WC WR WY WG).map {|i| "%"+i+";"}
    headings = %w(# New Access Network Description)

    widths = [3,4,7,20,38]
    header = hcols.zip(headings).map {|a,b| a+b}.formatrow(widths) + "%W;"
    puts header
    underscore = cols.zip(['-'*30]*5).map{|a,b| a+b}.formatrow(widths)

    grp = nil
    grp = groups[tempint].grp if !tempint.nil?
    print header
    print underscore if !@c_user.ansi
    temp = fetch_area_list(grp)
    fetch_area_list(grp).each_with_index {|area,i|
      pointer = get_pointer(@c_user,area.number)
      tempstr = (
      case pointer.access
      when "I"; "Inv"
      when "R"; "Read"
      when "W"; "Write"
      when "N"; "None"
      end)
      if (pointer.access != "I") or (user.level == 255) and (!area.delete) then
        more +=1   # .ljust(5)
        l_read = new_messages(area.number,pointer.lastread)
        print cols.zip([area.number,l_read,tempstr,area.group.groupname,area.name]).map{|a,b| "#{a}#{b}"}.formatrow(widths)
      end
      if more > 19 then
        cont = yes_num(prompt,true,true)
        more = 0
        break if !cont or cont.kind_of?(Fixnum)
        print
        print header
        print underscore if !@c_user.ansi
      end

    }
    return cont
  end


  def areachange(parameters)
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
        prompt = CRLF+"%W;Area #[#{@c_area}] (1-#{(a_total - 1)}) ? #{RET} to quit: "
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
          print "%G;Changing to #{area.group.groupname}: #{area.name} area"+CRLF
          break
        else
          if t == "N" then
            print "%WR;You do not have access%W;"
          else
            print "%WR;That area does not exist.%W;"
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
    result = nil
    a_list.each_with_index {|list,i|
      if list.number == num then
        result = i
        break
      end}
      return result
    end

    def zipscan(start)


      scanforaccess(@c_user)
      a_list = fetch_area_list(nil)
      start = find_current_area(a_list,@c_area)

      for i in start..(a_total - 1)
        #area = fetch_area(i)
        pointer = get_pointer(@c_user,i)
        l_read = new_messages(a_list[i].number,pointer.lastread)
        t = pointer.access
        if l_read > 0 then
          if pointer.zipread and (t !~ /[NI]/ or @c_user.level == 255) and (!a_list[i].delete) then
            @c_area = a_list[i].number
            print "%G;Changing to the #{a_list[i].group.groupname}: #{a_list[i].name} sub-board"+CRLF
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

    #-----------------Message Section-------------------

    def reply(mpointer)
      private = false
      print
      user = @c_user
      area = fetch_area(@c_area)
      pointer = get_pointer(@c_user,@c_area)

      if pointer.access !~ /[RN]/
        abs = absolute_message(area.number,mpointer)
        r_message = fetch_msg(abs)
        to = r_message.m_from
        to.strip! if r_message.network #strip for qwk/rep but not for fido. Why?
        while true
          prompt = "%G;Private (y,N,x - abort)? "
          reptype = getinp(prompt).upcase
          if (r_message.network or r_message.f_network) and reptype == "Y"
            replyemail(mpointer,@c_area)
            return
          else
            break
          end
        end

        case reptype
        when "Y"; private = true
        when "X"; return
        end

        title = r_message.subject

        print "%G;Title: #{title}"
        title = get_or_cr("%C;Enter Title (<CR> for old):%W; ", title)
        reply_text = []
        reply_text.push(">--- #{to} wrote ---")
        r_message.msg_text.each_line(DLIM) {|line| reply_text.push("> #{line.chop!}")}
        if @c_user.fullscreen then
          write "%W;"
          msg_file = write_quote_msg(reply_text)
          launch_editor(msg_file)
          suck_in_text(msg_file)
          prompt = "Post message #{YESNO}"
          saveit = yes(prompt, true, false,true)
        else
          saveit = lineedit(1,reply_text)
        end
        if (saveit) then
          system = fetch_system
          if !private then
            system.posts_today += 1
          else
            system.emails_today += 1
          end
          update_system(system)
          x = private ? 0 : @c_area
          savecurmessage(x, to, title, false,true,nil,nil,nil,nil)
          print private ? "Sending Private Mail..." : "%G;Saving Message.."
        else
          print "%WR;Message Cancelled.%W;"
        end
      end
    end

    def savecurmessage(x, to, title,exported,reply,destnode,destnet,intl,point)

      area = fetch_area(x)
      @lineeditor.msgtext << DLIM
      msg_text = @lineeditor.msgtext.join(DLIM)
      m_from = @c_user.name
      msg_date = Time.now.strftime("%Y-%m-%d %I:%M%p")
      absolute = add_msg(to,m_from,msg_date,title,msg_text,exported,false,destnode,destnet,intl,point,false, nil,nil,nil,
      nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,reply,area.number,nil,nil,nil,nil)
      add_log_entry(5,Time.now,"#{@c_user.name} posted msg # #{absolute}")
    end

    def get_or_cr(prompt, crvalue)
      until DONE
        tempstr = getinp(prompt)
        break if tempstr.upcase != "CR"
        crerror
      end
      emptyv(tempstr, crvalue)
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
      begin
      rescue
        print "wow"
      end
      @lineeditor.msgtext = []
      if File.exists?("#{FULLSCREENDIR}/#{msg_file}")
        IO.foreach("#{FULLSCREENDIR}/#{msg_file}") { |line| @lineeditor.msgtext.push(line.chomp!) }
      end
      #puts "rm #{FULLSCREENDIR}/#{msg_file}"
      happy = system("rm #{FULLSCREENDIR}/#{msg_file}")
      return true
    end


    def launch_editor(msg_file)

      launch = nil
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
      scanforaccess(@c_user)
      done = false
      area = fetch_area(@c_area)
      pointer = get_pointer(@c_user,area.number)

      if pointer.access[@c_area] =~ /[RN]/
        print "%WR;You do not have write access.%W;"
        return
      end

      print
      to = get_or_cr("%C;To (<CR> for All):%W; ", "ALL")
      prompt = "%G;Title:%W; "
      title = getinp(prompt)
      return if title == ""
      reply_text = ["***No Message to Quote***"]
      if @c_user.fullscreen then
        write "%W;"
        msg_file = write_quote_msg(nil)
        launch_editor(msg_file)
        suck_in_text(msg_file)
        prompt = "Post message #{YESNO}"
        saveit = yes(prompt, true, false,true)
      else
        saveit = lineedit(1,reply_text)
      end
      if saveit then
        savecurmessage(@c_area, to, title,false,false,nil,nil,nil,nil)
        @c_user.posted += 1
        update_user(@c_user)
        system = fetch_system
        system.posts_today += 1
        update_system(system)
      end
    end # of def post



    def display_fido_header(mpointer)
      area = fetch_area(@c_area)
      if (h_msg > 0) and (mpointer > 0) then
        u = @c_user
        fidomessage = fetch_msg(absolute_message(@c_area,mpointer))
        print
        print "%C;Org:%G; #{fidomessage.orgnet}/#{fidomessage.orgnode}"
        print "%C;Dest:%G; #{fidomessage.destnet}/#{fidomessage.destnode}"
        print "%C;q_msgid:%G; #{fidomessage.q_msgid}"
        # [[field, attr], ....]. if attr is missing, it is field.downcase
        fields = [ "Attribute", "Cost", ["Date Time", :msg_date], ["To", :m_to],
          ["From", :m_from], "Subject", "Area", "Msgid", "Path",
          ["TzUTZ", :tzutc],"CharSet", ["Tosser ID", :tid], ["Proc ID", :pid], "Intl",
          "Topt", "Fmpt", "Reply", "Origin",["QWK Message ID", :q_msgid],
        ["QWK Time Zone",:q_tz],["QWK Via",:q_via],["QWK Reply",:q_reply]]

        fields.each do |f|
          field, attr = (f.is_a? Array) ? f : [f, f.downcase]
          val = fidomessage.send(attr)
          print "%C;#{field}:%G; #{val}" if val
        end

        print
      else
        print "\r\n%Y;This message area is empty. Why not %G;[P]ost%Y; a Message?" if h_msg == 0
        print "\r\n%R;You haven't read any messages yet." if mpointer == 0 and h_msg > 0
      end
    end

    def parse_intl(address)

      happy = (/^(\d?):(\d{1,4})\/(.*)/) =~ address
      if happy then
        zone = $1;net = $2;node = $3
        grumpy = (/(\d{1,4})\.(\d{1,4})/) =~ node
        if grumpy then
          node = $1;point = $2
        end
      end
      return [zone,net,node,point]
    end

    def non_standard_zone(inzone)
      #puts "inzone #{inzone}"
      inzone = inzone[4..7] if inzone.length == 7
      num = inzone.to_i(16)
      #puts "num: #{num}"
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



    def displaymessage(mpointer,table,email)

      if mpointer != 0 then
        i = 0
        area = fetch_area(@c_area)
        pointer = get_pointer(@c_user,area.number)
        group = fetch_group_grp(area.grp)
        qwknet = get_qwknet(group)
        bbsid = ""
        bbsid = qwknet.bbsid if !qwknet.nil?
        u = @c_user

        if email then

          abs = email_absolute_message(mpointer,u.name)
        else
          abs = absolute_message(table,mpointer)
        end
        curmessage = fetch_msg(abs)
        if pointer.lastread < curmessage.absolute then
          pointer.lastread = curmessage.absolute
          update_pointer(pointer)
        end

        message = []
        tempmsg=convert_to_ascii(curmessage.msg_text)


        tempmsg.each_line(DLIM) {|line| message.push(line.chop!)} #changed from .each for ruby 1.9

        print
        write "%W;##{mpointer} %G;[%C;#{curmessage.absolute}%G;] "

        if curmessage.network then
          if !curmessage.q_tz.nil? then
            tzout = TIME_TABLE[curmessage.q_tz.upcase]
            tzout = non_standard_zone(curmessage.q_tz) if tzout.nil?
          end
        end
        write " %WG;*QWK*%W;" if curmessage.network
        write " %WB;*SMTP*%W;" if curmessage.smtp
        write " %WC;*FIDONET*%W;" if curmessage.f_network
        write " %WY;*EXPORTED*%W;" if curmessage.exported and !curmessage.f_network and !curmessage.network
        write " %WB;*REPLY*%W;" if curmessage.reply
        print ""
        write "%C;Date: "
        write"%M;#{curmessage.msg_date.strftime("%A the %d#{time_thingie(curmessage.msg_date)} of %B, %Y at %I:%M%p")}"
        write "%W;(%G;#{tzout}%W;)" if !tzout.nil?
        print        
        print "%C;To: %G;#{curmessage.m_to}%W;" # reset colors in case ansi is embedded in fields
        write "%C;From: %G;#{curmessage.m_from.strip}%W;" # reset colors in case ansi is embedded in fields
        if curmessage.f_network then
          out = "UNKNOWN"
          if !curmessage.intl.nil? then
            if curmessage.intl.length > 1 then
              o_adr = curmessage.intl.split[1]
              zone,net,node,point = parse_intl(o_adr)
              out = "#{zone}:#{net}/#{node}"
              out << ".#{point}" if !point.nil?
            end
          else out = get_orig_address(curmessage.msgid) end
          write " %G;(%C;#{out}%G;)" if !out.nil?
        end
        if curmessage.network then
          out = bbsid
          out = curmessage.q_via if !curmessage.q_via.nil?
        end
        write " %G;(%C;#{out}%G;)" if !out.nil?
        #  end
        print
        print "%C;Title: %G;#{curmessage.subject}%Y;"
        print
        print "%WG; #{"MESSAGE TEXT".center(@c_user.width - 2)}%W;"
        print
        j =7
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
        print "%W;" # reset colors at end of message display
      else
        print "%WR;Out of Range%W;"
      end
    end #displaymesasge

    def h_msg
      area = fetch_area(@c_area)
      h_msg = m_total(area.number)
    end

    def p_msg
      user = @c_user
      area = fetch_area(@c_area)
      pointer = get_pointer(@c_user,area.number)
      p_msg = m_total(area.number) - new_messages(area.number,pointer.lastread) # modified for db change
    end

    def messagemenu(zipread)
      scanforaccess(@c_user)
      @who.user(@c_user.name).where="Message Menu"
      update_who_t(@c_user.name,"Reading Messages")
      out = "Read"
      if zipread then
        out = "ZIPread"
        return if !zipscan(1)
      end
      theme = get_user_theme(@c_user) 
      pointer = get_pointer(@c_user,@c_area)
      area = fetch_area(@c_area)
      l_read = new_messages(area.number,pointer.lastread)
      readmenu(
      :out => out,
      :initval => p_msg,
      :range => 1..h_msg,
      :theme => theme,
      :l_read => l_read,
      :loc => READ

      ) {|sel, mpointer, moved, out|

        mpointer = h_msg if mpointer.nil?
        mpointer = h_msg if mpointer > h_msg

        if !sel.integer?
          parameters = Parse.parse(sel)
          sel.gsub!(/[-\d]/,"")
        end

        if moved
          if (mpointer > 0) and (mpointer <= h_msg) then # range check
            showmessage(mpointer)
          end

        end
        theme = get_user_theme(@c_user) 
        case sel
        when @cmd_hash["email"] ; run_if_ulevel("email") {emailmenu}
        when @cmd_hash["post"] ; run_if_ulevel("post") {post}
        when @cmd_hash["page"] ; run_if_ulevel("page") {page}
        when @cmd_hash["leave"] ; run_if_ulevel("leave") {leave}
        when @cmd_hash["who"] ; run_if_ulevel("who") {displaywho}
        when @cmd_hash["areachange"] ; run_if_ulevel("areachange") {mpointer = areachange(parameters)}
        when @cmd_hash["reread"] ; run_if_ulevel("reread") {showmessage(mpointer)}
        when @cmd_hash["killmsg"] ; run_if_ulevel("killmsg") {killmessage(mpointer)}
        when @cmd_hash["replymsg"] ; run_if_ulevel("replymsg") {replytomessage(mpointer)}
        when @cmd_hash["fullheader"] ; run_if_ulevel("fullheader") {display_fido_header(mpointer)}
        when @cmd_hash["masskill"] ; run_if_ulevel("masskill") {mass_kill(parameters)}
        when @cmd_hash["readmenu"] ; run_if_ulevel("readmenu") {ogfileout("readmnu",1,true)}
        when @cmd_hash["readquit"] ; run_if_ulevel("readquit") {mpointer = true if !theme.nomainmenu}
        end
     if theme.nomainmenu  #wbbs mode
      case sel
      when @cmd_hash["leave"] ; run_if_ulevel("leave") {leave}
      when @cmd_hash["umaint"] ; run_if_ulevel("umaint") {usermenu}
      when @cmd_hash["kill_log"] ; run_if_ulevel("kill_log") {clearlog}
      when @cmd_hash["amaint"] ; run_if_ulevel("amaint") {areamaintmenu}
      when @cmd_hash["bmaint"] ; run_if_ulevel("bmaint") {bullmaint}
      when @cmd_hash["gmaint"] ; run_if_ulevel("gmaint") {groupmaintmenu}
      when @cmd_hash["tmaint"] ; run_if_ulevel("tmaint") {thememaint}
      when @cmd_hash["dmaint"] ; run_if_ulevel("dmaint") {doormaint}
      when @cmd_hash["omaint"] ; run_if_ulevel("omaint") {telnetmaint}
      when @cmd_hash["smaint"] ; run_if_ulevel("smaint") {screenmaint}
      when @cmd_hash["areachange"] ; run_if_ulevel("areachange") {areachange(parameters)}
      when @cmd_hash["bulletins"] ; run_if_ulevel("bulletins") {bullets(parameters)}
      when @cmd_hash["teleconference"]
        if IRC_ON then
          run_if_ulevel("teleconference") {teleconference(nil)}
        else
          print "%WR;Teleconference is disabled!%W;\r\n"
        end
        
      when @cmd_hash["kick"] ; run_if_ulevel("kick") {youreoutahere}
      when @cmd_hash["questionaire"] ; run_if_ulevel("questionaire") {questionaire}
      when @cmd_hash["doors"] ; run_if_ulevel("doors") {doors(parameters)}
      when @cmd_hash["other"] ; run_if_ulevel("other") {bbs(parameters)}
      when @cmd_hash["email"] ; run_if_ulevel("email") {sendemail(true)}
      when @cmd_hash["usrsetting"] ; run_if_ulevel("usrsetting") {usersettings}
      when @cmd_hash["readmnu"] ; run_if_ulevel("readmnu") {messagemenu(false)}
      when @cmd_hash["zipread"] ; run_if_ulevel("zipread") {messagemenu(true)}
      when @cmd_hash["info"] ; run_if_ulevel("info") {ogfileout("user_information",1,true)}
      when @cmd_hash["version"] ; run_if_ulevel("version") {version}
      when @cmd_hash["log"] ; run_if_ulevel("log") {displaylog}
      when @cmd_hash["sysopmnu"] ; run_if_ulevel("sysopmnu") {ogfileout("sysopmnu",1,true)}

    end
    end
        p_return = [mpointer,h_msg,out] # evaluate so this is the value that is returned

      }
    end

    def killmessage(mpointer)

      if mpointer > 0 then
        area = fetch_area(@c_area)
        abs = absolute_message(area.number,mpointer) #modified for db change
        d_msg = fetch_msg(abs) #modified for db change

        if d_msg.locked == true then
          print CRLF + "%WR;Cannot Delete. Message Locked.%W;"
          return
        end
        pointer = get_pointer(@c_user,area.number)
        t = pointer.access
        if !((t =~ /[CM]/) or
          (@c_user.level == 255) ) then
            print CANNOTKILLMESSAGESERROR
            return
          end

          if h_msg > 0
            delete_msg(abs)
            print "%WR;Message ##{mpointer} [#{abs}] deleted.%W;"
          else
            print CRLF+"%WR;No Messages%W;"
          end
        else
          print CRLF+"%WR;You can't delete message 0, because it doesn't exist!%W;"
        end
      end

      def mass_kill(parameters)

        area = fetch_area(@c_area)
        start,stop = parameters[0..1]
        pointer = get_pointer(@c_user,@c_area)

        if (start < 1) or (start > h_msg) or (stop < 1) or (stop > h_msg) then
          print "%WR;Out of Range dude!%W;"
          return
        end

        if !((pointer.access =~ /[CM]/) or (@c_user.level == 255) ) then
          print CANNOTKILLMESSAGESERROR
          return
        end

        first = absolute_message(area.number,start)  #this need rewriting for the new db format
        last = absolute_message(area.number,stop)
        prompt = "%WR;Delete messages #{start} to #{stop}%W; #{YESNO}"
        delete_msgs(area.number,first,last) if yes(prompt, true, false,true)
      end

      def replytomessage(mpointer)
        if mpointer > 0 then
          reply(mpointer)
        else
          print "%WR;You haven't read a message yet.%W;"
        end
      end

      def showmessage(mpointer)

        area = fetch_area(@c_area)
        if (h_msg > 0) and (mpointer > 0) then
          displaymessage(mpointer,area.number,false)
        else
          print "\r\n%Y;This message area is empty. Why not %G;[P]ost%Y; a Message?" if h_msg == 0
          print "\r\n%R;You haven't read any messages yet." if mpointer == 0
        end
      end

      #----------------Area Maintaince Section---------------------------

      def displayarea(number)
        area = fetch_area(number)
        write "\r\n%R;#%W;#{number} %G; #{area.name}"
        write "%R; [DELETED]" if area.delete
        write "%R; [LOCKED]" if area.locked
        print ""
        if area.netnum > -1 then
          out = area.netnum
        else
          out = "NONE"
        end

        print <<-here
    %C;Default Access: %G;#{area.d_access}
    %C;Validated Access: %G;#{area.v_access}
    %C;QWK/REP Net # %G;#{out} 
    %C;FidoNet Area: %G;#{area.fido_net}
    %C;Last Modified: %G;#{area.modify_date.strftime("%A the %d#{time_thingie(area.modify_date)} of %B, %Y at %I:%M%p")}
    %C;Total Messages: %G;#{m_total(area.number)}
    %C;Group: %G;#{area.group.groupname}
    %C;Prune Level: %G;#{area.prune}
here

      end #displayarea

      def areamaintmenu
        readmenu(
        :initval => 0,
        :range => 0..(a_total - 1),
        :loc => AREA
        ) {|sel, apointer, moved|
          displayarea(apointer) if moved
          case sel
          when "/"; displayarea(apointer)
          when "Q"; apointer = true
          when "A"; apointer = addarea
          when "NN"; changeqwkrep(apointer)
          when "P"; changepurge(apointer)
          when "FN"; changefidoarea(apointer)
          when "CF"; clearfidoarea(apointer)
          when "W"; displaywho
          when "PU"; page
          when "N"; changeareaname(apointer)
          when "D"; changedefaultaccess(apointer)
          when "V"; changevalidatedaccess(apointer)
          when "K"; deletearea(apointer)
          when "S"; lockarea(apointer)
          when "G"; leave
          when "CG"; changegroup(apointer)
          when "?"; gfileout ("areamnu")
          end # of case
          p_return = [apointer,(a_total - 1)]
        }
      end

  def changepurge(apointer)

        area = fetch_area(apointer)
        print

        prompt = "Select New message limit (to be enforced at maintenance time or 0 for none: "
        area.prune = getnum(prompt,0,999999)
        update_area(area)
        print "Area Updated"
      end


      def deletearea(apointer)
        if apointer <= 1
          print "%WR%You cannot delete area 0 or 1.%W%"
          return
        end

        area = fetch_area(apointer)

        if area.delete
          area.delete = false
          print "Area ##{apointer} UNdeleted"
        else
          area.delete = true
          print "Area ##{apointer} deleted."
        end
        update_area(area)
      end

      def lockarea(apointer)

        area = fetch_area(apointer)

        if area.locked then
          area.locked = false
          print "Area ##{apointer} UNlocked"
        else
          area.locked = true
          print "Area ##{apointer} locked."
        end
        update_area(area)
      end

      def changevalidatedaccess(apointer)

        area = fetch_area(apointer)

        prompt = "Enter new validated access level for board #{apointer}: "
        tempstr2 = getinp(prompt).upcase
        if tempstr2 =~ /[NIWRMC]/
          area.v_access = tempstr2
          print "Board #{apointer} validated access changed to #{tempstr2}"
          update_area(area)
        else
          print "%WR;Invalid Selection%W;"
        end
      end


      def changegroup(apointer)

        area = fetch_area(apointer)
        groups = fetch_groups
        print
        print "Select New Group #"
        groups.each_index {|j| print "#{j}: #{groups[j].groupname}"}
        prompt = "Enter new group number for board #{apointer}: "
        tempint = getnum(prompt,0,groups.length - 1)
        area.grp = groups[tempint].grp
        update_group(area)
        print "Area Updated"
      end

      def changedefaultaccess(apointer)

        area = fetch_area(apointer)

        prompt = "Enter new default access level for board #{apointer}: "
        tempstr2 = getinp(prompt).upcase
        if tempstr2 =~ /[NIWRMC]/
          area.d_access = tempstr2
          print "Board #{apointer} default access changed to #{tempstr2}"
          update_area(area)
        else
          print "%WR;Invalid Selection%W;"
        end
      end

      def addarea

        print ADDAREAWARNING
        while true
          prompt = "Enter new area name: "
          name = getinp(prompt) {|n| n != ""}
          if name.length > 40 then
            print "%WR;Name too long. 40 Character Maximum%W;"
          else
            break
          end
        end

        commit = yes("Are you sure #{YESNO}",true,false,true)
        if commit then
          add_area(name,"W","W",nil,nil,nil)
          apointer = a_total - 1
        else
          print "%WR;Cancelled.%W;"
          apointer = a_total - 1
          return
        end

      end

      def changeqwkrep(apointer)

        area = fetch_area(apointer)

        print QWKREPWARNING

        while true
          prompt = "Enter new QWK/REP number (N / no mapping): "
          netnum = getinp(prompt) {|n| n != ""}
          if netnum =="N" or netnum == "n"
            area.netnum = -1
            break
          end
          if netnum.to_i > -1 and netnum.to_i < 10000 then
            area.netnum = netnum.to_i
            break
          end
        end
        update_area(area)
        print
      end
    
    


      def changeareaname(apointer)

        area = fetch_area(apointer)

        while true
          prompt = "Enter new area name: "
          name = getinp(prompt) {|n| n != ""}
          if name.length > 40 then
            print "Name too long. 40 Character Maximum"
          else
            break
          end
        end
        area.name = name
        update_area(area)
        print
      end

      def changefidoarea(apointer)

        area = fetch_area(apointer)

        while true
          prompt = "Enter new FidoNet Area Mapping: "
          fido_net= getinp(prompt) {|n| n != ""}
          if fido_net.length > 40 then
            print "Area too long. 40 Character Maximum"
          else
            break
          end
        end
        area.fido_net = fido_net.upcase
        update_area(area)
      end

      def clearfidoarea(apointer)

        area = fetch_area(apointer)
        commit = yes("Clear Fidonet Area Mapping. Are you sure #{YESNO}",false,false,true)

        if commit then
          area.fido_net = nil
          update_area(area)
          print
          print "Cleared Fido Mapping"
        else
          print
          print "Not Cleared."
        end
      end
    end # class Session

