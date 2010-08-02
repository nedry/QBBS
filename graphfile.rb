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
        @session.write line + "\r" 
      } 
    else
      @session.print "\n#{outfile} has run away...please tell sysop!\n"
    end
    2.times { @session.print }
  end

  def fileout
    if File.exists?(filename) 
      IO.foreach(filename) { |line| 
        @session.write line + "\r" 
      } 
    else
      @session.print "\n#{filename} has run away...please tell sysop!\n"
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
