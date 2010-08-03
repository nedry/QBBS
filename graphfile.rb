require 'consts'

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
    if File.exists?(outfile)
      IO.foreach(outfile) { |line|
        j = j + 1
        user = @session.c_user
        if j == user.length and user.more then
          cont = @session.moreprompt
          j = 1
        end
        break if !cont
        out = parse_text_commands(line)
        if !out.gsub!("%PAUSE%","").nil? and @session.logged_on  then
          @session.yes("%WPress %Y<--^%W: ",true,false,true)
        end
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
    text_commands = {
      "%NODE%"  => @session.node.to_s,
      "%TIMEOFDAY%" => @session.timeofday,
      "%USERNAME%" => @session.c_user.name,
      "%U_LDATE%" => @session.c_user.laston.strftime("%A %B %d, %Y"),
      "%U_LTIME%" => @session.c_user.laston.strftime("%I:%M%p (%Z)"),
      "%IP%" => @session.c_user.ip
    }

    #line = line.to_s.gsub("\t",'')

    text_commands.each_pair {|code, result|
      line.gsub!(code,result)
    }
  end
  return line
end
