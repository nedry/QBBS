require 'tools.rb'
require 'messagestrings.rb'
require 'menu.rb'
require 'doors.rb'
require 'encodings.rb'

#TODO: clean up the line spacing and indentation in here
#
class Session

  def messagefirstmenu
    theme = get_user_theme(@c_user)
    done = false

    GraphFile.new(self, "messagemenu",true).ogfileout(0)
    prompt = theme.message_prompt

    getinp(prompt) {|inp|


      parameters = Parse.parse(inp)

      case inp.upcase
      when @cmd_hash["msgmenu"] ; run_if_ulevel("msgmenu") { GraphFile.new(self, "messagemenu",true).ogfileout(0)}
      when @cmd_hash["read"] ; run_if_ulevel("read") {messagemenu(false)}
      when @cmd_hash["write"] ; run_if_ulevel("write") {post}
      when @cmd_hash["msgareach"] ; run_if_ulevel("msgareach") {areachange(parameters)}
      when @cmd_hash["who"] ; run_if_ulevel("who") {displaywho}
      when @cmd_hash["msgzipread"] ; run_if_ulevel("msgzipread") {messagemenu(true)}
      when @cmd_hash["teleconference"]
        if IRC_ON then
          run_if_ulevel("teleconference") {teleconference(nil)}
        else
          print "%WR; Teleconference is disabled! %W;\r\n"
        end
      when @cmd_hash["msgexit"] ; run_if_ulevel("msgexit") { done = true}
      end
      done
    }

  end


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
      print "%WG; ZipRead Complete! %W;"
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
        nntpreferences = r_message.nntpreferences

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
          #prompt = "Post message #{YESNO}"
          #saveit = yes(prompt, true, false,true)
          saveit = false
          saveit = true if @lineeditor.msgtext.length > 0
        else
          saveit,title = lineedit(:reply_text => reply_text,:title => title)
        end
				@debuglog.push("pretitle: #{title}")
        if (saveit) then
          system = fetch_system
          if !private then
            system.posts_today += 1
          else
            system.emails_today += 1
          end
          update_system(system)
          x = private ? 0 : @c_area
          savecurmessage(x, to, :title => title,:reply => true, :nntpreferences => nntpreferences)
          print private ? "Sending Private Mail..." : "%G;Saving Message.."
        else
          print "%WR;Message Cancelled.%W;"
        end
      end
    end

    def savecurmessage(x, to,options = {})

      default = {:title => "", :exported => false,  :reply => false, :destnode => nil, :destnet => nil, :intl => nil, :point => nil, :nntpreferences => "" }
      options = default.merge(options)

      area = fetch_area(x)
      if !@c_user.signature.nil? then
        @lineeditor.msgtext << "" << "---"
        @c_user.signature.split("\n").each {|text| @lineeditor.msgtext << text}
      end
      @lineeditor.msgtext << DLIM
    @debuglog.push("title: #{options[:title]}")

      absolute = add_msg(to,@c_user.name,area.number, :subject => options[:title], :msg_text => @lineeditor.msgtext.join(DLIM),
      :exported => options[:exported], :destnode => options[:destnode],:destnet => options[:destnet], :intl => options[:intl],
      :point => options[:topt], :reply => options[:reply], :nntpreferences => options[:nntpreferences])

      add_log_entry(5,Time.now,"#{@c_user.name} posted msg # #{absolute}")
    end



    def savesystemmessage(x, to, title,text)
      #just to save a message from th    ende SYSTEM account.  The whole message saving system is kludgy.  Rewrite!

      area = fetch_area(x)
      text << DLIM
      absolute = add_msg(to,"SYSTEM",area.number, :subject => title, :msg_text => text.join(DLIM))
      add_log_entry(5,Time.now,"SYSTEM posted msg # #{absolute}")
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
      if File.exists?("#{FULLSCREENDIR}/#{msg_file}") then
        IO.foreach("#{FULLSCREENDIR}/#{msg_file}") { |line| @lineeditor.msgtext.push(line.chomp!) }
      end

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

      door_do("#{launch} #{FULLSCREENDIR}/#{msg_file}","")
      print ("%W;")
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
        #saveit = false
        #saveit = true if @lineeditor.msgtext.length > 0
        prompt = "Post message #{YESNO}"
        saveit = yes(prompt, true, false,true)
      else
        saveit,title = lineedit(:reply_text => reply_text,:title => title)
      end
							@debuglog.push("pretitle: #{title}")

      if saveit then
        savecurmessage(@c_area, to, :title => title)
        @c_user.posted += 1
        update_user(@c_user)
        system = fetch_system
        system.posts_today += 1
        update_system(system)
      end
    end # of def post

    def msg_debug(mpointer)
      area = fetch_area(@c_area)
      if (h_msg > 0) and (mpointer > 0) then
        print "--- message text dump ---"
        dmsg = fetch_msg(absolute_message(@c_area,mpointer))
        dmsg.msg_text.each_char {|c| write c;write("(#{c.ord})")}
      end
    end

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
          ["QWK Time Zone",:q_tz],["QWK Via",:q_via],["QWK Reply",:q_reply],
          ["NNTP Organization",:organization],"references",
          "Bytes","Lines","xref","xtrace","nntppostinghost","xoriginalbytes",
        "MsgId","nntpreferences"]

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
				
        #in case a pointer got trashed.
        pointer.lastread = 0 if pointer.lastread.nil?

        if pointer.lastread < curmessage.absolute then
          pointer.lastread = curmessage.absolute
          update_pointer(pointer)
        end

        message = []
        tempmsg=convert_to_ascii(curmessage.msg_text)

        #some QWK/REP messages seem to use linefeeds instead of 227 char characters
        #to indicate EOL

        tempmsg.gsub!(10.chr,DLIM)
        tempmsg.each_line(DLIM) {|line| message.push(line.chop!)} #changed from .each for ruby 1.9



        j = GraphFile.new(self, "message").profileout(curmessage,mpointer)

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

    def messagemenu(zip)
      scanforaccess(@c_user)
      @who.user(@c_user.name).where="Message Menu"
      update_who_t(@c_user.name,"Reading Messages")

      if zip then
        @c_area = 1
        if !zipscan(1) then
          zip = false
          return
        end
      end
      theme = get_user_theme(@c_user)
      pointer = get_pointer(@c_user,@c_area)
      area = fetch_area(@c_area)
      l_read = new_messages(area.number,pointer.lastread)

      readmenu(
      :zip => zip,
      :initval => p_msg,
      :range => 1..h_msg,
      :theme => theme,
      :l_read => l_read,
      :loc => READ

      ) {|sel, mpointer, moved, zip|

        mpointer = h_msg if mpointer.nil?
        mpointer = h_msg if mpointer > h_msg

        parameters = Parse.parse(sel)


        if moved

          if (mpointer > 0) and (mpointer <= h_msg) then # range check
            showmessage(mpointer)
          end

        end
        theme = get_user_theme(@c_user)
        case sel
        when "MD"; msg_debug(mpointer)
        when "TB"; testbitch("bbsinfo")
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
          when @cmd_hash["uprofile"] ; run_if_ulevel("uprofile") {profilemenu}
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
          when @cmd_hash["feedback"] ; run_if_ulevel("feedback") { sendemail(true)}
          when @cmd_hash["teleconference"]
            if IRC_ON then
              run_if_ulevel("teleconference") {teleconference(nil)}
            else
              print "%WR; Teleconference is disabled! %W;\r\n"
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
          when @cmd_hash["version"] ; run_if_ulevel("version") {ogfileout("version",1,true)}
          when @cmd_hash["log"] ; run_if_ulevel("log") {displaylog}
          when @cmd_hash["sysopmnu"] ; run_if_ulevel("sysopmnu") {ogfileout("sysopmnu",1,true)}

          end
        end
        p_return = [mpointer,h_msg,zip] # evaluate so this is the value that is returned

      }
    end


    def testbitch (filename)
      print "Updating Synchronet BBS list details"
      savesystemmessage(@c_area, "SBL", SYSTEMNAME,GraphFile.new(self, filename).process_only)
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
        %C;NNTP Newsgroup: %G;#{area.nntp_net}
        %C;NajorBBS Net Newsgroup: %G;#{area.mbbs_net}
        %C;NNTP Pointer: %G;#{area.nntp_pointer}
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
          when "NG"; changenntpgroup(apointer)
          when "MB"; changembbsgroup(apointer)
          when "D"; changedefaultaccess(apointer)
          when "V"; changevalidatedaccess(apointer)
          when "K"; deletearea(apointer)
          when "S"; lockarea(apointer)
          when "NP";changenntppointer(apointer)
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

      def changenntppointer(apointer)

        area = fetch_area(apointer)
        print

        prompt = "Select New nntp pointer: "
        area.nntp_pointer = getnum(prompt,0,999999)
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
        if !tempint.nil? then
          area.grp = groups[tempint].grp
          update_group(area)
          print "%WG;Area Updated%W;"
        else
          print "%WR;Aborted%W;"
        end
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
          add_area(name,"W","W",nil,nil,nil,nil)
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

      def changenntpgroup(apointer)

        area = fetch_area(apointer)

        while true
          prompt = "Enter new NNTP Group name: "
          nntp_net = getinp(prompt) {|n| n != ""}
          if nntp_net.length > 40 then
            print "NNTP Group too long. 40 Character Maximum"
          else
            break
          end
        end
        area.nntp_net = nntp_net
        update_area(area)
        print
      end

      def changembbsgroup(apointer)

        area = fetch_area(apointer)

        while true
          prompt = "Enter new MBBS Export map name: "
          mbbs_net = getinp(prompt) {|n| n != ""}
          if mbbs_net.length > 40 then
            print "MBBS Export map too long. 40 Character Maximum"
          else
            break
          end
        end
        area.mbbs_net = mbbs_net
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

