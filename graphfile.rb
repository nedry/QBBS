require 'consts'
require 'rubygems'
require 'socket'
require 'sinatra'
require "db/db_system.rb"

class GraphFile
  attr_accessor :session, :filename, :override



  def initialize(session, filename, override = true)
    @session = session
    @filename = filename
    @override = override
  end

  def outfile
    graphfile = TEXTPATH + filename + ".gra"
    plainfile = TEXTPATH + filename + ".txt"
    if override then
      return File.exists?(graphfile) ? graphfile : plainfile
    else
      return filename
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
    if File.exists?(outfile)
      IO.foreach(outfile) { |line|
        j = j + 1
        user = @session.c_user
        if j == user.length and user.more and !nomore then
          cont = @session.moreprompt
          j = 1
        end
        break if !cont
        out = parse_text_commands(line)
        if !out.gsub!("%PAUSE%","").nil? and @session.logged_on  then
          @session.yes("%WPress %Y<--^%W: ",true,false,true)
        end
        nomore = true if !out.gsub!("%NOMORE%","").nil?   #disable more prompt for this file
        @session.write out + "\r"
      }
    else
      @session.print "\n#{outfile} has run away...please tell sysop!\n"
    end
    2.times { @session.print }
  end

  def fileout(fname)
    if File.exists?(fname)
      IO.foreach(fname) { |line|
        out = parse_text_commands(line)

        @session.write out + "\r"
      }
    else
      @session.print "\n#{fname} has run away...please tell sysop!\n"
    end
    2.times { @session.print }
  end

  def gfileout
    graphfile = TEXTPATH + filename + ".gra"
    plainfile = TEXTPATH + filename + ".txt"
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
    ualias = "<NONE>" if @session.c_user.alias.nil?
    ratio = (posts  / calls) * 100
    text_commands = {
      "%NODE%"  => @session.node.to_s,
      "%TIMEOFDAY%" => @session.timeofday,
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
      "%IP%" => @session.c_user.ip,
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
      "%NEWUSERS%" =>  system.newu_today.to_s
    }

    #line = line.to_s.gsub("\t",'')
  
    text_commands.each_pair {|code, result|
      line.gsub!(code,result)
    }
  end
  return line
end
