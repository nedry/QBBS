require 'consts'
require 'rubygems'
require 'socket'
require 'sinatra'
require "db/db_system.rb"
require 'db/db_themes'

class GraphFile
  attr_accessor :session, :filename, :override



  def initialize(session, filename, override = true)
    @session = session
    @filename = filename
    @override = override
    @u_space = disk_used_space(ROOT_PATH).to_s
    @f_space = disk_free_space(ROOT_PATH).to_s
    @t_space =  disk_total_space(ROOT_PATH).to_s
    @pf_space = disk_percent_free(ROOT_PATH).to_s
  end

  def outfile
    theme = get_user_theme(@session.c_user)
    graphfile =  theme.text_directory + filename + ".gra"
    plainfile =  theme.text_directory + filename + ".txt"
    if override then
      return File.exists?(graphfile) ? graphfile : plainfile
    else
      return filename
    end
  end

  def process_only

    out = []
    if File.exists?(outfile)
      IO.foreach(outfile) { |line|
        deporter = parse_text_commands(line)
        out  << deporter.gsub("\n", "")

      }
    else
      out =  ["\n#{outfile} has run away...please tell sysop!\n"]
    end
    return out
  end

  def tih
    if !TIH.nil? then
      j = 0
      get_history(TIH).split(LF.chr).each { |line|
        j = j + 1
        if j == @session.c_user.length and @session.c_user.more  then
          cont = @session.moreprompt
          j = 1
        end
        @session.print parse_text_commands(line)
      }
    else
      @session.print
      @session.print "%WG;Today in History is disabled%W;"
      @session.print
    end
  end

  def existfileout(offset)
    test = outfile
    if File.exists?(test) then
      ogfileout(offset)
      return true
    else
      return false
    end
  end

  def ogfileout(offset)
    j = offset
    cont = true
    nomore = false
    display = true
    nonstop = false
    theme = get_user_theme(@session.c_user)

    if File.exists?(outfile)
      IO.foreach(outfile) { |line|
        j = j + 1 if display
        user = @session.c_user
        if j == user.length and user.more and !nomore then
          cont = @session.moreprompt
          j = 1
        end
        break if !cont
        out = parse_text_commands(line)

        if !out.gsub!("%PAUSE%","").nil? and @session.logged_on and !nonstop then
          inp = @session.getinp(theme.pause_prompt,false)
          case inp.upcase
          when "N"
            nonstop = true
          when "Q"
            break
          end
        end

        # TODO: Use if out.include?("%whatever%") if you're just checking for
        # strings
        #
        # TODO: Move all these within an if @session.logged_on block rather
        # than repeat the check everywhere.
        if !out.gsub!("%WHOLIST%","").nil? and @session.logged_on  then
          @session.displaywho
        end
        if !out.gsub!("%FB%","").nil? and @session.logged_on  then
          doit = @session.yes("%W;Do you want to leave a comment to the SysOp #{NOYES} ",false,false,true)
          @session.sendemail(true) if doit
        end
        if !out.gsub!("%LASTCALL%","").nil? and @session.logged_on  then
          @session.display_wall
        end
        if !out.gsub!("%PROFILE%","").nil? and !@session.c_user.profile_added  then
          @session.print theme.profile_comlete_entry
        end
        if !out.gsub!("%QOTD%","").nil? and @session.logged_on  then
          @session.qotd
        end
        if !out.gsub!("%TIH%","").nil? and @session.logged_on  then
          tih
        end
        if !out.gsub!("%BULLET%","").nil? and @session.logged_on  then
          @session.bullets(0)
        end
        if !out.gsub!("%SYS%","").nil? and @session.logged_on  then
          display = false
          display = true if @session.c_user.level == 255
        end
        if !out.gsub!("%REGUSER%","").nil? and @session.logged_on  then
          display = true
        end
        nomore = true if !out.gsub!("%NOMORE%","").nil?   #disable more prompt for this file
        @session.write out + "\r" if display
      }
    else
      @session.print "\n#{outfile} has run away...please tell sysop!\n"
    end
    @session.print
  end

  def padding(string, p)
    s = string || " "
    s = s.ljust(p.to_i) if p
    return s
  end

  def matcher(text)
    /\|#{text}(\d*)([^\|]*)\|/
  end

  # text substitution including %s
  def replace_line(line, text, obj_data)
    line.gsub!(matcher(text)) {|m|
      out = ""
      pad = $1
      if obj_data
        out = $2.gsub("%s", obj_data.to_s)
      end
      padding(out,pad)
    }
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
		
  def profileout(obj,index)
    theme = get_user_theme(@session.c_user)
    area = fetch_area(@session.c_area)
		    group = fetch_group_grp(area.grp)
        qwknet = get_qwknet(group)
        bbsid = ""
        bbsid = qwknet.bbsid if !qwknet.nil?

    f_net = nil
    i = 0

    if obj.kind_of?(Message) then
      m_date = "[NO DATE]"

      m_date = obj.msg_date.strftime(theme.profile_date_format.gsub('%Z',time_thingie(obj.msg_date))) if !obj.msg_date.nil?
      if obj.network then
        if !obj.q_tz.nil? then
          tzout = TIME_TABLE[obj.q_tz.upcase]
          tzout = non_standard_zone(obj.q_tz) if tzout.nil?
        end
      end

      if obj.f_network then
        f_net = "UNKNOWN"
        if !obj.intl.nil? then
          if obj.intl.length > 1 then
            o_adr = obj.intl.split[1]
            zone,net,node,point = parse_intl(o_adr)
            f_net = "#{zone}:#{net}/#{node}"
            f_net << ".#{point}" if !point.nil?
          end
        else f_net = get_orig_address(obj.msgid) end
      end
      if obj.network then
        q_net = bbsid
        q_net = obj.q_via if !obj.q_via.nil?
      end
    end
    if File.exists?(outfile)

      IO.foreach(outfile) { |line|
        line = parse_text_commands(line.force_encoding("IBM437"))
        replace_line(line, 'NUMBER', index.to_s)

        # TODO: move each of these blocks into its own method to make this one
        # easier to read
        if obj.kind_of?(User) then
          replace_line(line, 'UNAME' ,obj.name)
          replace_line(line, 'REALNAME', obj.real_name)
          replace_line(line, 'SEX', obj.sex)
          replace_line(line, 'AGE', obj.age)
          replace_line(line, 'ALIASES', obj.aliases)
          replace_line(line, 'CITYSTATE', obj.citystate)
          replace_line(line, 'VPHONE', obj.voice_phone)
          replace_line(line, 'PDESC', obj.p_description)
          replace_line(line, 'URL', obj.url)
          replace_line(line, 'MOVIE', obj.fav_movie)
          replace_line(line, 'TV', obj.fav_tv)
          replace_line(line, 'MUSIC', obj.fav_music)
          replace_line(line, 'INST', obj.insturments)
          replace_line(line, 'FOOD', obj.fav_food)
          replace_line(line, 'SPORT', obj.fav_sport)
          replace_line(line, 'HOBBIES', obj.hobbies)
          replace_line(line, 'GEN1', obj.gen_info1)
          replace_line(line, 'GEN2', obj.gen_info2)
          replace_line(line, 'SUM', obj.summary)
        end
        if obj.kind_of?(Bbslist) then
          modify_date = obj.modify_date ? obj.modify_date.strftime("%B %d, %Y") : nil
          replace_line(line, 'DATE', modify_date)
          replace_line(line, 'NAME', obj.name)
          replace_line(line, 'USER', obj.user)
          replace_line(line, 'TELNET', obj.number)
          replace_line(line, 'SYSOP', obj.sysop)
          replace_line(line, 'EMAIL', obj.email)
          replace_line(line, 'LOCATION', obj.location)
          replace_line(line, 'SOFTWARE', obj.software)
          replace_line(line, 'MSGS', obj.msgs)
          replace_line(line, 'SUBS', obj.subs)
          replace_line(line, 'FILES', obj.files)
          replace_line(line, 'DIRS', obj.dirs)
          replace_line(line, 'MEGS', obj.megs)
          replace_line(line, 'TERMINAL', obj.terminal)
          replace_line(line, 'WEBSITE', obj.website)
          line.gsub!(matcher('NETWORK')) {|m|
            if !obj.network.nil? then
              out = "#{$2}"
              obj.network.split("|").each {|line| out << "\r\n   #{line.strip}"}
              padding(out,$1)
            end
          }
          line.gsub!(/\|DESC(\d*)([^\|]*)\|/){|m|
            if !obj.desc.nil? then
              out = "#{$2}"
              obj.desc.split("|").each {|line| out << "\r\n   #{line.strip}"}
              padding(out,$1)
            end
          }
          # TODO: move this pattern into a method too
          line.gsub!(/\|LOCAL(\d*)([^\|]*)\|/){||m|  out = ""; out = padding($2,$1) if !obj.imported; out}
          line.gsub!(/\|IMPT(\d*)([^\|]*)\|/){|m|  out = ""; out = padding($2,$1) if obj.imported; out}
          line.gsub!(/\$LOCKED(\d*)([^\|]*)\|/){|m|  out = ""; out = padding($2,$1) if obj.locked; out}
        end
        if obj.kind_of?(Message) then
          line.gsub!(/\|QWK(\d*)([^\|]*)\|/){|m|  out = ""; out = padding($2,$1) if obj.network; out}
          line.gsub!(/\|NNTP(\d*)([^\|]*)\|/){|m|  out = ""; out = padding($2,$1) if obj.usenet_network; out}
          line.gsub!(/\|SMTP(\d*)([^\|]*)\|/){|m|  out = ""; out = padding($2,$1) if obj.smtp; out}
          line.gsub!(/\|FIDONET(\d*)([^\|]*)\|/){|m|  out = ""; out = padding($2,$1) if obj.f_network; out}
          line.gsub!(/\|EXPORTED(\d*)([^\|]*)\|/){|m|  out = ""; out = padding($2,$1) if obj.exported and !obj.usenet_network and !obj.f_network and !obj.network; out}
          line.gsub!(/\|REPLY(\d*)([^\|]*)\|/){|m|  out = ""; out = padding($2,$1) if obj.reply; out}


          replace_line(line, 'ABS', obj.absolute)
          replace_line(line, 'DATE', m_date)
          replace_line(line, 'TZ', tzout)
          replace_line(line, 'TO', obj.m_to)
          replace_line(line, 'FROM', obj.m_from)
          replace_line(line, 'FNET', f_net)
          replace_line(line, 'QNET', q_net)
          replace_line(line, 'TITLE', obj.subject)
          replace_line(line, 'AREA', area.name)
        end
        line.gsub!(/\|CR\|/,"\r")
        @session.write line + "\r" if !line.strip.empty?
        i+=1
      }
        else
          @session.print "\n#{outfile} has run away...please tell sysop!\n"
          return i
        end
        @session.print
        return i
      end

      def fileout(fname)

        if File.exists?(fname)
          IO.foreach(fname) { |line|
            out = parse_text_commands(line.force_encoding("IBM437"))

            @session.write out + "\r"
          }
        else
          @session.print "\n#{fname} has run away...please tell sysop!\n"
        end
        2.times { @session.print }
      end

      def gfileout
        theme = get_user_theme(@session.c_user)
        graphfile =  theme.text_directory + filename + ".gra"
        plainfile =  theme.text_directory + filename + ".txt"
        if @session.c_user.ansi == TRUE and File.exists?(graphfile)
          fileout(graphfile)
        else
          fileout(plainfile)
        end
      end
    end

    def parse_text_commands(line)
      if @session.logged_on then
        system = fetch_system
        aname = ""
        if !@session.c_area.nil? then
          area = fetch_area(@session.c_area)
          aname = area.name
        end
        posts = @session.c_user.posted.to_f
        calls =  @session.c_user.logons.to_f
        ualias = @session.c_user.alias
        ualias = "<NONE>" if ualias.nil?
        tspacem = @t_space.to_i / 1048576
        ratio = (posts  / calls) * 100

        ip= @session.c_user.ip
        ip= "UNKNOWN" if ip.nil?
        ratio = 0 if calls == 0
        text_commands = {
          "%AREA%" => aname,
          "%U_SPACE%" => @u_space,
          "%F_SPACE%" => @f_space,
          "%T_SPACE%" => @t_space,
          "%PU_SPACE%" =>  @pf_space,
          "%NODE%"  => @session.node.to_s,
          "%TIMEOFDAY%" => @session.timeofday,
          "%YEAR%" => Time.now.year.to_s,
          "%USERNAME%" => @session.c_user.name,
          "%U_LDATE%" => @session.c_user.laston.strftime("%A %B %d, %Y"),
          "%U_LTIME%" => @session.c_user.laston.strftime("%I:%M%p (%Z)"),
          "%U_LEVEL%" => @session.c_user.level.to_s,
          "%U_LOGONS%" => @session.c_user.logons.to_s,
          "%U_POSTS%" => @session.c_user.posted.to_s,
          "%U_RATIO%" => ratio.to_i.to_s,
          "%U_ADDR%" => @session.c_user.address,
          "%U_CITYSTATE%" => @session.c_user.citystate,
          "%U_ALIAS%" => ualias,
          "%IP%" => ip,
          "%BBSNAME%" => SYSTEMNAME,
          "%FIDOADDR%" => "#{FIDOZONE}:#{FIDONET}/#{FIDONODE}#{"." + FIDOPOINT.to_s if FIDOPOINT != 0}",
          "%VER%" => VER,
          "%WEBVER%" => "Sinatra #{Sinatra::VERSION}",
          "%TNODES%" => NODES.to_s,
          "%SYSOP%" => SYSOPNAME,
          "%RVERSION%" => RUBY_VERSION,
          "%PLATFORM%" => RUBY_PLATFORM,
          "%PID%" => $$.to_s,
          "%STIME%" => Time.now.strftime("%I:%M%p (%Z)"),
          "%SDATE%" => Time.now.strftime("%A %B %d, %Y"),
          "%SYSLOC%" => SYSTEMLOCATION,
          "%TLOGON%" => system.total_logons.to_s,
          "%LOGONS%" => system.logons_today.to_s,
          "%POSTS%" =>  system.posts_today.to_s,
          "%EMAILS%" =>  system.emails_today.to_s,
          "%FEEDBACK%" =>  system.feedback_today.to_s,
          "%NEWUSERS%" =>  system.newu_today.to_s,
          "%TMESSAGES%" => system_m_total.to_s,
          "%TUSERS%" => u_total.to_s,
          "%TDOORS%" => d_total.to_s,
          "%TNODES%" => NODES.to_s,
          "%TSPACEM%" =>  tspacem.to_s,
          "%TAREAS%" => a_total.to_s
        }

        #line = line.to_s.gsub("\t",'')
        begin
          text_commands.each_pair {|code, result|
            line.gsub!(code,result)
          }
        rescue
          @session.debuglog.push( "-ERROR: in graphfile.rb: #{$!}")
          add_log_entry(8,Time.now,"Error in graphfile.rb: #{$!}")
        end
      end
      return line
    end
