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


  def profileout(user)
    theme = get_user_theme(@session.c_user)

    if File.exists?(outfile)
      IO.foreach(outfile) { |line|
	line = parse_text_commands(line.force_encoding("IBM437"))
        line.gsub!(/%UNAME(\d*)%/){|m| padding(user.name,$1)}
        line.gsub!(/%REALNAME(\d*)%/){|m| padding(user.real_name,$1)}
        line.gsub!(/%SEX(\d*)%/){|m| padding(user.sex,$1)}
        line.gsub!(/%AGE(\d*)%/){|m| padding(user.age.to_s,$1)}
        line.gsub!(/%ALIASES(\d*)%/){|m| padding(user.aliases,$1)}
        line.gsub!(/%CITYSTATE(\d*)%/){|m| padding(user.citystate,$1)}
        line.gsub!(/%VPHONE(\d*)%/){|m| padding(user.voice_phone,$1)}
        line.gsub!(/%PDESC(\d*)%/){|m| padding(user.p_description,$1)}
        line.gsub!(/%URL(\d*)%/){|m| padding(user.url,$1)}
        line.gsub!(/%MOVIE(\d*)%/){|m| padding(user.fav_movie,$1)}
        line.gsub!(/%TV(\d*)%/){|m| padding(user.fav_tv,$1)}		
        line.gsub!(/%TV(\d*)%/){|m| padding(user.fav_music,$1)}	
        line.gsub!(/%INST(\d*)%/){|m| padding(user.insturments,$1)}	
        line.gsub!(/%FOOD(\d*)%/){|m| padding(user.fav_food,$1)}	
        line.gsub!(/%SPORT(\d*)%/){|m| padding(user.fav_sport,$1)}
        line.gsub!(/%HOBBIES(\d*)%/){|m| padding(user.hobbies,$1)}
        line.gsub!(/%GEN1(\d*)%/){|m| padding(user.gen_info1,$1)}	
        line.gsub!(/%GEN2(\d*)%/){|m| padding(user.gen_info2,$1)}	
        line.gsub!(/%SUM(\d*)%/){|m| padding(user.summary,$1)}	

        @session.write line + "\r"
      }
    else
      @session.print "\n#{outfile} has run away...please tell sysop!\n"
    end
     @session.print 
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
