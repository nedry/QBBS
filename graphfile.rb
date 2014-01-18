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

  def padding(string,p)
    s = " "
    s = string if !string.nil?
    s = s.ljust(p.to_i) if !p.nil?
    return s
  end


  def profileout(obj,index)

    theme = get_user_theme(@session.c_user)
    area = fetch_area(@session.c_area)

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
            o_adr = curmessage.intl.split[1]
            zone,net,node,point = parse_intl(o_adr)
            f_net = "#{zone}:#{net}/#{node}"
            f_net << ".#{point}" if !point.nil?
          end
        else f_net = get_orig_address(curmessage.msgid) end
      end
      if obj.network then
        q_net = bbsid
        q_net = obj.q_via if !obj.q_via.nil?
      end
    end
    if File.exists?(outfile)

      IO.foreach(outfile) { |line|
        line = parse_text_commands(line.force_encoding("IBM437"))
        line.gsub!(/\|NUMBER(\d*)([^\|]*)\|/){|m| out = "" ; pad = $1;pad = $1;  out = $2.gsub("%s",index.to_s) ;  padding(out,pad) }

        if obj.kind_of?(User) then

          line.gsub!(/\|UNAME(\d*)([^\|]*)\|/){|m| out = "" ; pad = $1; out = $2.gsub("%s",obj.name) if !obj.name.nil?;  padding(out,pad) }
          line.gsub!(/\|REALNAME(\d*)([^\|]*)\|/){|m| out = "" ; pad = $1; out = $2.gsub("%s",obj.real_name) if !obj.real_name.nil?;  padding(out,pad) }
          line.gsub!(/\|SEX(\d*)([^\|]*)\|/){|m| out = "" ; pad = $1; out = $2.gsub("%s",obj.sex) if !obj.sex.nil?;  padding(out,pad) }
          line.gsub!(/\|AGE(\d*)([^\|]*)\|/){|m| out = "" ; pad = $1; out = $2.gsub("%s",obj.age.to_s) if !obj.age.nil?;  padding(out,pad) }
          line.gsub!(/\|ALIASES(\d*)([^\|]*)\|/){|m| out = "" ; pad = $1; out = $2.gsub("%s",obj.aliases) if !obj.aliases.nil?;  padding(out,pad) }
          line.gsub!(/\|CITYSTATE(\d*)([^\|]*)\|/){|m| out = "" ; pad = $1; out = $2.gsub("%s",obj.citystate) if !obj.citystate.nil?;  padding(out,pad) }
          line.gsub!(/\|VPHONE(\d*)([^\|]*)\|/){|m| out = "" ; pad = $1; out = $2.gsub("%s",obj.voice_phone) if !obj.voice_phone.nil?;  padding(out,pad) }
          line.gsub!(/\|PDESC(\d*)([^\|]*)\|/){|m| out = "" ; pad = $1; out = $2.gsub("%s",obj.p_description) if !obj.p_description.nil?;  padding(out,pad) }
          line.gsub!(/\|URL(\d*)([^\|]*)\|/){|m| out = "" ; pad = $1; out = $2.gsub("%s",obj.url) if !obj.url.nil?;  padding(out,pad) }
          line.gsub!(/\|MOVIE(\d*)([^\|]*)\|/){|m| out = "" ; pad = $1; out = $2.gsub("%s",obj.fav_movie) if !obj.fav_movie.nil?;  padding(out,pad) }
          line.gsub!(/\|TV(\d*)([^\|]*)\|/){|m| out = "" ; pad = $1; out = $2.gsub("%s",obj.fav_tv) if !obj.fav_tv.nil?;  padding(out,pad) }
          line.gsub!(/\|MUSIC(\d*)([^\|]*)\|/){|m| out = "" ; pad = $1; out = $2.gsub("%s",obj.fav_music) if !obj.fav_music.nil?;  padding(out,pad) }
          line.gsub!(/\|INST(\d*)([^\|]*)\|/){|m| out = "" ; pad = $1; out = $2.gsub("%s",obj.insturments) if !obj.insturments.nil?;  padding(out,pad) }
          line.gsub!(/\|FOOD(\d*)([^\|]*)\|/){|m| out = "" ; pad = $1; out = $2.gsub("%s",obj.fav_food) if !obj.fav_food.nil?;  padding(out,pad) }
          line.gsub!(/\|SPORT(\d*)([^\|]*)\|/){|m| out = "" ; pad = $1; out = $2.gsub("%s",obj.fav_sport) if !obj.fav_sport.nil?;  padding(out,pad) }
          line.gsub!(/\|HOBBIES(\d*)([^\|]*)\|/){|m| out = "" ; pad = $1; out = $2.gsub("%s",obj.hobbies) if !obj.hobbies.nil?;  padding(out,pad) }
          line.gsub!(/\|GEN1(\d*)([^\|]*)\|/){|m| out = "" ; pad = $1; out = $2.gsub("%s",obj.gen_info1) if !obj.gen_info1.nil?;  padding(out,pad) }
          line.gsub!(/\|GEN2(\d*)([^\|]*)\|/){|m| out = "" ; pad = $1; out = $2.gsub("%s",obj.gen_info2) if !obj.gen_info2.nil?;  padding(out,pad) }
          line.gsub!(/\|SUM(\d*)([^\|]*)\|/){|m| out = "" ; pad = $1; out = $2.gsub("%s",obj.summary) if !obj.summary.nil?;  padding(out,pad) }
        end
        if obj.kind_of?(Bbslist) then

          line.gsub!(/\|DATE(\d*)([^\|]*)\|/){|m| out = "";  pad = $1; out = $2.gsub("%s",obj.modify_date.strftime("%B %d, %Y")) if !obj.modify_date.nil?;  padding(out,pad) if !obj.modify_date.nil?}
          line.gsub!(/\|NAME(\d*)([^\|]*)\|/){|m| out = "" ; pad = $1; out = $2.gsub("%s",obj.name) if !obj.name.nil?;  padding(out,pad) }
          line.gsub!(/\|USER(\d*)([^\|]*)\|/){|m| out = "" ; pad = $1; out = $2.gsub("%s",obj.user) if !obj.user.nil?;  padding(out,pad) }
          line.gsub!(/\|TELNET(\d*)([^\|]*)\|/){|m| out = "" ; pad = $1; out = $2.gsub("%s",obj.number.to_s) if !obj.number.nil?;  padding(out,pad) }
          line.gsub!(/\|SYSOP(\d*)([^\|]*)\|/){|m| out = "" ; pad = $1; out = $2.gsub("%s",obj.sysop) if !obj.sysop.nil?;  padding(out,pad) }
          line.gsub!(/\|EMAIL(\d*)([^\|]*)\|/){|m| out = "" ; pad = $1; out = $2.gsub("%s",obj.email) if !obj.email.nil?;  padding(out,pad) }
          line.gsub!(/\|LOCATION(\d*)([^\|]*)\|/){|m| out = "" ; pad = $1; out = $2.gsub("%s",obj.location) if !obj.location.nil?;  padding(out,pad) }
          line.gsub!(/\|SOFTWARE(\d*)([^\|]*)\|/){|m| out = "" ; pad = $1; out = $2.gsub("%s",obj.software) if !obj.software.nil?;  padding(out,pad) }
          line.gsub!(/\|MSGS(\d*)([^\|]*)\|/){|m| out = "" ; pad = $1; out = $2.gsub("%s",obj.msgs.to_s) if !obj.msgs.nil?;  padding(out,pad) }
          line.gsub!(/\|SUBS(\d*)([^\|]*)\|/){|m| out = "" ; pad = $1; out = $2.gsub("%s",obj.subs.to_s) if !obj.subs.nil?;  padding(out,pad) }
          line.gsub!(/\|FILES(\d*)([^\|]*)\|/){|m| out = "" ; pad = $1; out = $2.gsub("%s",obj.files.to_s) if !obj.files.nil?;  padding(out,pad) }
          line.gsub!(/\|DIRS(\d*)([^\|]*)\|/){|m| out = "" ; pad = $1; out = $2.gsub("%s",obj.dirs.to_s) if !obj.dirs.nil?;  padding(out,pad) }
          line.gsub!(/\|MEGS(\d*)([^\|]*)\|/){|m| out = "" ; pad = $1; out = $2.gsub("%s",obj.megs.to_s) if !obj.megs.nil?;  padding(out,pad) }
          line.gsub!(/\|TERMINAL(\d*)([^\|]*)\|/){|m| out = "" ; pad = $1; out = $2.gsub("%s",obj.terminal) if !obj.terminal.nil?;  padding(out,pad) }
          line.gsub!(/\|WEBSITE(\d*)([^\|]*)\|/){|m| out = "" ; pad = $1; out = $2.gsub("%s",obj.website) if !obj.website.nil?;  padding(out,pad) }
          line.gsub!(/\|NETWORK(\d*)([^\|]*)\|/){|m|
            if !obj.network.nil? then
              out = "#{$2}"
              obj.network.split("|").each {|line| out << "\r\n   #{line.strip}"}
              padding(out,$1)
            end}
            line.gsub!(/\|DESC(\d*)([^\|]*)\|/){|m|
              if !obj.desc.nil? then
                out = "#{$2}"
                obj.desc.split("|").each {|line| out << "\r\n   #{line.strip}"}
                padding(out,$1)
              end}
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


              line.gsub!(/\|ABS(\d*)([^\|]*)\|/) {|m| out = "" ; pad = $1; out = $2.gsub("%s",obj.absolute.to_s) if !obj.absolute.nil?;  padding(out,pad) }
              line.gsub!(/\|DATE(\d*)([^\|]*)\|/){|m| out = "" ; pad = $1; out = $2.gsub("%s",m_date) if !m_date.nil?; padding(out,pad) }
              line.gsub!(/\|TZ(\d*)([^\|]*)\|/){|m| out = "" ; pad = $1; out = $2.gsub("%s",tzout) if !tzout.nil?;  padding(out,pad) }
              line.gsub!(/\|TO(\d*)([^\|]*)\|/){|m| out = "" ; pad = $1; out = $2.gsub("%s",obj.m_to.strip) if !obj.m_to.nil?;  padding(out,pad) }
              line.gsub!(/\|FROM(\d*)([^\|]*)\|/){|m| out = "" ; pad = $1; out = $2.gsub("%s",obj.m_from.strip) if !obj.m_from.nil?;  padding(out,pad) }
              line.gsub!(/\|FNET(\d*)([^\|]*)\|/){|m| out = "" ; pad = $1; out = $2.gsub("%s",f_net) if !f_net.nil?;  padding(out,pad) }
              line.gsub!(/\|QNET(\d*)([^\|]*)\|/){|m| out = "" ; pad = $1; out = $2.gsub("%s",q_net) if !q_net.nil?;  padding(out,pad) }
              line.gsub!(/\|TITLE(\d*)([^\|]*)\|/){|m| out = "" ; pad = $1; out = $2.gsub("%s",obj.subject.strip) if !obj.subject.nil?;  padding(out,pad) }
              line.gsub!(/\|AREA(\d*)([^\|]*)\|/) {|m| out = "" ; pad = $1; out = $2.gsub("%s",area.name) if !area.name.nil?;  padding(out,pad) }
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
          "%FIDOADDR%" => "#{FIDOZONE}:#{FIDONET}/#{FIDONODE}.#{FIDOPOINT}",
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
