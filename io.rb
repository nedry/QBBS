require 'tools.rb'
#require 'consts.rb'
require "wrap.rb"
require 'chat/irc'

class Session
  include Logger

  # Input a line a character at a time. 
  def getstr(echo, wrapon, width, prompt, chat, overwrite) 
    whole = "" # return value
    suppress = false # prevent telnet control codes being treated as user input
    idle = 0
    tick = Time.now.min.to_i

    warn  = @c_user ? RIDLEWARN : LIDLEWARN
    limit = @c_user ? RIDLELIMIT : LIDLELIMIT

    todotime = limit - warn
    warned = false


    whole = @wrap.to_s # takes care of nil
    i = whole.length

    @wrap = ''
    @socket.write whole

    while true do
      char = 0
      if select([@socket],nil,nil,0.1) != nil then 
        char = @socket.getc.ord  #this is a 1.9 hack... 1.8 behaviour returned the ascii value without the .ord
      else 
        if @c_user != nil 
        #  page = @who.user(@c_user.name).page if @who.user(@c_user.name) != nil
        #  unless (page.nil? || page.empty? )
          #  print; page.each {|x| print x}; page.clear
         #   prompt += whole if prompt != nil
          #  write prompt
         # end
        end

        time = Time.now
        tick = 0 if time.min.to_i == 0 

        if time.min.to_i > tick then 
          idle = idle + 1
          tick = time.min.to_i 
        end


        if !chat
          warned = warntimeout(idle, warn, warned, limit, todotime, prompt)
        else
          printchat(whole, prompt)
        end
      end
      next if char == 0

      idle = 0
      warned = false
      case char 
      when TELNETCMD; suppress = true
      when CR
        if !overwrite then
          @socket.write CRLF
        else
          w_len = 0;p_len = 0
          w_len = whole.length if !whole.nil?
          p_len = prompt.length if !prompt.nil?
          b_len = w_len + p_len
          b_len.times {@socket.write BS.chr}
          b_len.times {@socket.write(" ")}
          b_len.times {@socket.write BS.chr}
          sleep(0.1)
        end
        break
      when BS;  i, whole = delchar(i, whole)
      when DBS; i, whole = delchar(i, whole) #for UNIX based Telnet 
      when PRINTABLE 
        i = i + 1
        if !suppress then
          whole << char.chr 
          @socket.write(echo ? char.chr : NOECHOCHAR.chr)
        end
        whole,newline = wrapstr(whole, i, width, char) if wrapon
      end  #of case

      break if newline
      suppress = false if char < 250
    end #of iterator

    @socket.flush 
    return whole 
  end 

  def parse_ircc(line)
    line = line.to_s.gsub("\t",'')
    if @logged_on then
      IRCCOLORTABLE.each_pair {|color, result|
        line.gsub!(color) {@c_user.ansi ? result : ''}
      }
    end
    return line
  end

  def c_strip(line)
    if !line.nil?
      COLORTABLE.each_pair {|color, result|
        line.gsub!(color,"")
      }
    end
    return line
  end

  def printchat(whole, prompt)
    if !@irc_client.nil? then
      if @irc_client.isdata then
        out = nil
        m = @irc_client.getline
        if m.kind_of? IRC::Message::Private then
          happy = (/^[\x1](ACTION)(.*)[\x1]/) =~ m.params 
          if !happy.nil? then
            out = "* #{m.sourcenick}#{$2}#{CRLF}%W"
          else
            if m.dest == @irc_alias then 
              @gd_mode = true if m.sourcenick == GD_IRCUSER and m.params.strip == "+++"
              @gd_mode = false if m.sourcenick == GD_IRCUSER and m.params.strip == "---"

              if @gd_game and m.sourcenick == GD_IRCUSER then
                out = "%C#{m.params}#{CRLF}%W" 

              else
                out = "%RPM:%B<%G#{m.sourcenick}%B>%C #{m.params}#{CRLF}%W"
              end
            else

              @gd_game = true if m.sourcenick == GD_IRCUSER and m.params.strip == "***GAME START"
              @gd_game = false if m.sourcenick == GD_IRCUSER and m.params.strip == "***GAME STOP"

              if @gd_game and m.sourcenick == GD_IRCUSER then
                if m.params[0..2] != "-+-"
                  out = "%C#{m.params}#{CRLF}%W"
                else out = nil end
              else
                out = "%B<#{m.sourcenick}>%C #{m.params}#{CRLF}%W"
              end
            end
          end

        elsif m.kind_of? IRC::Message::Nick then
          (/^:(.*)!(.*)/) =~ m.message 
          if $1 == @irc_alias then 
            @irc_alias = m.params
            out ="%Y*** You are now known as #{@irc_alias}#{CRLF}%W"

          else
            out ="%Y*** #{$1} is now known as #{m.params}#{CRLF}%W"
          end
        elsif m.kind_of? IRC::Message::Part then
          (/^:(.*)!(.*)/) =~ m.message 
          out ="%Y*** #{$1} has left the channel #{m.dest}#{CRLF}%W"

        elsif m.kind_of? IRC::Message::Join then
          (/^:(.*)!(.*)/) =~ m.message 
          if $1 == @irc_alias then
            @irc_client.part(@irc_channel)
            @irc_channel = m.params
            out ="%Y*** You have joined the channel #{@irc_channel}#{CRLF}%W"
          else
            out ="%Y*** #{$1} has joined this channel#{CRLF}%W"
          end
        elsif m.kind_of? IRC::Message::Numeric then
          case m.command

          when IRC::RPL_NAMREPLY
            (/^:(\S*)\s(\d*)\s(\S*)\s(.*):(.*)/) =~ m.message 
            chan = " #{$4}"; users = $5
            happy = (/=(.*)/) =~ chan
            chan = $1 if !happy.nil?
            out = "%Y*** Users on#{chan}#{users} #{CRLF}%W"

          when IRC::RPL_WHOISUSER
            (/^:(\S*)\s(\d*)\s(\S*)\s(\S*)\s(\S*)\s(\S*)\s\*\s:(.*)/) =~ m.message 
            nick = $4; host = $6; desc = $7;rname= $5
            out = "%Y*** #{nick} is #{rname}@#{host} (#{desc})#{CRLF}%W"

          when IRC::RPL_WHOISIDLE
            (/^:(\S*)\s(\d*)\s(\S*)\s(\S*)\s(\S*)\s(\d*)\s(\d*)(.*)/) =~ m.message
            idle_minutes = $5.to_i / 60
            out = "%Y*** #{$4} has been idle for #{idle_minutes} minute(s).#{CRLF}%W"

          when IRC::RPL_WHOISCHANNELS
            (/^:(.*):(.*)/) =~ m.message 
            out ="%Y*** on channels: #{$2}#{CRLF}%W"

          when IRC::RPL_WHOISSERVER
            (/^:(\S*)\s(\d*)\s(\S*)\s(\S*)\s(.*):(.*)/) =~ m.message 
            out ="%Y*** on irc via server #{$5}(#{$6})#{CRLF}%W"

          when IRC::RPL_VERSION
            (/^:(\S*)\s(\d*)\s(\S*)\s(.*)/) =~ m.message 
            out = "%Y*** #{$4}#{CRLF}%W"

          when IRC::RPL_CREATED
            (/^:\S\s(\S*)\s(\S*)\s(.*)/) =~ m.message 
            puts "rpl_created"
            out ="%Y*** #{$3}#{CRLF}%W"

          when IRC::RPL_LIST
            (/^:(\S*)\s(\d*)\s(\S*)\s(\S*)\s(\d*)/) =~ m.message 
            out = "%Y*** There are #{$5} user(s) on channel #{$4}#{CRLF}%W"

          else
            (/^:(.*):(.*)/) =~ m.message 
            #(/^:\S\s(\S*)\s(\S*)\s(.*)/) =~ m.message 
            out ="%Y*** #{$2}#{CRLF}%W"
          end

        elsif m.kind_of? IRC::Message::ServerNotice then
          out ="#{m.params}#{CRLF}%W"
        end

        if !out.nil? then

          w_out = WordWrapper.wrap(out,@c_user.width)

          if (whole == '')  then

            write parse_ircc(w_out)
            if !@irc_client.isdata
              # print
              # write prompt
            end   
          else
            @chatbuff.push(w_out)
          end
        end



      end
    end
  end

  def warntimeout(idle, warn, warned, limit, todotime, prompt)
    if (idle >= limit)
      print; print "%RIdle time limit exceeded.  Disconnecting!"
      print "%WNO CARRIER"
      sleep(5)
      hangup
    end

    if (idle >= warn) and (!warned) 
      if todotime > 1 then tempstr = "minutes" else tempstr = "minute" end
      print; print "%RYou have #{todotime} #{tempstr} in which to do something!%W"
      write prompt
      warned = true
    end

    return warned
  end

  def wrapstr(whole, i, width, char)

    newline = false
    if (i >= width - 4)  then
      if char != 32
        wlen = 0
        @wrap = whole.scan(/\w+/).last
        wlen = @wrap.length if @wrap != nil
        wlen.times{@socket.write(BS.chr)}
        wlen.times{@socket.write(" ")}
        @socket.write(CRLF)
        endbit = whole.length - wlen
        whole.slice!(endbit..whole.length)
        newline = true
      else
        @socket.write CRLF
        @wrap = ""
        newline = true
      end
    end
    return [whole,newline]
  end

  def delchar(i, whole)
    if i > 0
      @socket.write BS.chr
      return i-1, whole.chop
    else
      return i, whole
    end
  end
  # what the hell... this because of doors.rb causing an error
  def getcmd(prompt, echo, size, chat,ovrwrite)


    if @cmdstack.cmd.empty?
      write prompt
      tempstr = getstr(echo,NOWRAP,size,prompt,chat,ovrwrite).strip
      @cmdstack.pullapart(tempstr)
    end



    nilv(@cmdstack.cmd.shift, "")
  end

  def getcmdandtest(prompt, echo, size, chat, errmsg,ovrwrite)
    while true do
      t = getcmd(prompt, echo, size, chat,ovrwrite)
      break if yield t
      print errmsg
    end
    print
    return t
  end

  def _getinputlen(prompt, echo, size, chat)
    getcmdandtest(prompt, echo, size, chat, '',false) {|cmd|
      cmd.length >= size
    }
  end

  def getinputlen(prompt, echo, size, chat, errmsg = nil)
    if block_given?
      while true do
        t = _getinputlen(prompt, echo, size, chat)
        break if yield t
        print errmsg
      end
      print
      return t
    else
      _getinputlen(prompt, echo, size, chat)
    end
  end

  # pass in arguments as symbols, e.g.
  #   getinp(prompt, :chat, :nonempty)
  def getinp(prompt, *args)
    chat = args.include?(:chat)
    overwrite = args.include?(:overwrite)
    nonempty = args.include?(:nonempty)
    # print "in getinp"
    if block_given? or nonempty
      # print "block given"
      while true do
        t = getcmd(prompt, ECHO, 0, chat,overwrite)
        t = t.strip # since we almost never want trailing whitespace
        unless (nonempty and t.empty?) # fail right away if this happens
	 if block_given? then  #FIX... only yield if there is a block
          break if yield t
	 else
	  break
	 end
        end
      end
      print
      return t
    else
      getcmd(prompt, ECHO, 0, chat, false)
    end
  end

  def _getnum(prompt, low = nil, high = nil)
    while true
      a = getinp(prompt)
      if a == ""
        return nil
      elsif !a.integer?
        print "Input must be a number"
      else
        a = a.to_i
        if (low && (a < low)) or (high && (a > high))
          print "Must be between #{low} and #{high}"
        else
          return a
        end
      end
    end
  end

  def getnum(prompt, low = nil, high = nil, errmsg = "")
    if block_given?
      while true
        t = _getnum(prompt, low, high)
        return t if yield t
        print errmsg
      end
    else
      return _getnum(prompt, low, high)
    end
  end

  def getpwd(prompt, &block)
    getinputlen(prompt, NOECHO, 3, false, &block).strip.upcase
  end

  def getandconfirmpwd
    while true
      p1 = getpwd("Enter new password: ")
      break if p1 == ""
      p2 = getpwd("Enter again to confirm: ")
      break if p1 == p2
      print "Passwords don't match - try again"
    end
    p1 == "" ? nil : p1
  end

  def get_max_length(prompt,len,msg)

    while true
      temp = getinp(prompt).strip
      if temp.length > len then
        print "%R#{msg} too long.  40 Character Maximum"
      else break end
    end
    return temp
  end


  def yes_num(prompt,default,overwrite)
    validanswers = {"Y" => true, "N" => false, ""=> default}
    ans = ''
    while true
      t = getcmd(prompt, ECHO, 0, false,overwrite)
      ans = t.upcase.strip
      validanswers.has_key?(ans)
      result = validanswers[ans]

      if result.nil? then
        number = (/(\d+)/) =~ ans
        result = $1.to_i
        break if number
      else
        break 
      end
    end
    return result
  end

  def yes(prompt,default,chat, overwrite)
    validanswers = {"Y" => true, "N" => false, ""=> default}
    ans = ''

    t = getcmd(prompt, ECHO, 0, chat,overwrite)
    ans = t.upcase.strip
    validanswers.has_key?(ans)
    result = validanswers[ans]


    return result
  end
  def hangup 
    @socket.flush 
    @socket.close 
  end     

  #make sure everything goes through this!
  def parse_c(line)
    line = line.to_s.gsub("\t",'')
    if @logged_on then
      COLORTABLE.each_pair {|color, result|
        line.gsub!(color) {@c_user.ansi ? result : ''}
      }
    end
    return line
  end

  def parse_celerity(line)
    line = line.to_s.gsub("\t",'')
    if @logged_on then
      CELERITY_COLORTABLE.each_pair {|color, result|
        line.gsub!(color) {@c_user.ansi ? result : ''}
      }
    end
    return line
  end

  # Write line without CR 
  def write(line = '') 
    out = parse_c(line.to_s)
    @socket.write parse_celerity(out)
  end 

  # Write line with CR 
  def print(line = '') 
    line = parse_c(line.to_s.gsub("\n","#{CRLF}"))
    @socket.write(parse_celerity(line) + CRLF)
  end

  def moreprompt
    moreprompt = yes("*** More [Y,n]? ", true, false,true)
  end

  def telnetsetup
    # put the remote telnet client into "character at a time mode"
    # TELNET protocol sucks!
    [255,251,1,255,251,3].each {|i| write i.chr}
  end

  def existfileout (filename,offset,override)
    graphfile = TEXTPATH + filename + ".gra"
    plainfile = TEXTPATH + filename + ".txt"
    test = filename
    if override then
      test = File.exists?(graphfile) ? graphfile : plainfile
    end 
    if File.exists?(test) then 
      ogfileout(filename,offset,override)
      return true
    else
      return false
    end
  end
  def ogfileout (filename,offset,override)

    graphfile = TEXTPATH + filename + ".gra"
    plainfile   = TEXTPATH + filename + ".txt"

    outfile = filename

    if override then
      outfile = File.exists?(graphfile) ? graphfile : plainfile 
    end

    j = offset
    cont = true
    if File.exists?(outfile) 
      IO.foreach(outfile) { |line| 
        j = j + 1
        if j == @c_user.length and @c_user.more then
          cont = moreprompt
          j = 1
        end
        break if !cont 
        write line + "\r" 
      } 
    else
      print "\n#{outfile} has run away...please tell sysop!\n"
    end
    print; print
  end

  def fileout (filename)
    if File.exists?(filename) 
      IO.foreach(filename) { |line| write line + "\r" } 
    else
      print "\n#{filename} has run away...please tell sysop!\n"
    end
    print; print
  end

  def gfileout (filename)
    graphfile = TEXTPATH + filename + ".gra"
    plainfile = TEXTPATH + filename + ".txt"
    if @c_user.ansi == TRUE
      fileout(File.exists?(graphfile) ? graphfile : plainfile)
    else
      fileout(plainfile)
    end
  end

end # class Session
