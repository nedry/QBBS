require 'tools.rb'
#require 'consts.rb'
require "wrap.rb"
require 'chat/irc'
require 'irc_conference'
require 'graphfile'

module IOUtils
  # I/O utils. Depends on:
  # - getcmd
  # - print
  # - write

  def telnetsetup
    # put the remote telnet client into "character at a time mode"
    # TELNET protocol sucks!
    [255,251,1,255,251,3].each {|i| write i.chr}
  end

  def yes(prompt, default, chat, overwrite)
    validanswers = {"Y" => true, "N" => false, ""=> default}
    t = getcmd(prompt, ECHO, 0, chat, overwrite)
    ans = t.upcase.strip
    validanswers[ans]
  end

  def moreprompt
    moreprompt = yes("*** More [Y,n]? ", true, false,true)
  end

  def yes_num(prompt,default,overwrite)
    validanswers = {"Y" => true, "N" => false, ""=> default}
    while true
      t = getcmd(prompt, ECHO, 0, false, overwrite)
      ans = t.upcase.strip
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

  def apply_color(colortable, text, ansi)
    colortable.each_pair {|color, result|
      text = text.gsub(color) {ansi ? result : ''}
    }
    return text
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

  # pass in arguments as symbols, e.g.
  #   getinp(prompt, :chat, :nonempty)
  def getinp(prompt, *args)
    chat = args.include?(:chat)
    overwrite = args.include?(:overwrite)
    nonempty = args.include?(:nonempty)
    if block_given? or nonempty
      while true do
        t = getcmd(prompt, ECHO, 0, chat,overwrite)
        t = t.strip # since we almost never want trailing whitespace
        unless (nonempty and t.empty?) # fail right away if this happens
          break unless block_given?
          break if yield t
        end
      end
      print
      return t
    else
      getcmd(prompt, ECHO, 0, chat, false)
    end
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
        print "%WR;#{msg} too long.  40 Character Maximum%W;"
      else break end
    end
    return temp
  end
end

class Session
  include Logger
  include IOUtils
  include IrcConference

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
        if !@c_user.nil? and new_pages(@c_user) > 0 then
          pages = get_all_pages(@c_user)
          print; pages.each {|x| print "%W;PAGE %W;(%C;#{fetch_user(x.from).name}%W;): %WY;#{x.message}%W;"}
          prompt += whole if !prompt.nil? 
           write prompt
           clear_pages(@c_user)
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

  def warntimeout(idle, warn, warned, limit, todotime, prompt)
    if (idle >= limit)
      print; print "%WR;Idle time limit exceeded.  Disconnecting!%W;"
      print
      print "%WR;NO CARRIER%W;"
      sleep(5)
      hangup
    end

    if (idle >= warn) and (!warned) 
      screen = get_user_screen(@c_user)
      if SCREENSAVER  and @logged_on and !screen.nil? then
        print "%WR;Activating Screen Saver...%W;"
        sleep(1)
        door_do(screen.path,"")
        print (CLS)
        print (HOME)
        idle = 0
        warned = true
        write prompt
      else
      if todotime > 1 then tempstr = "minutes" else tempstr = "minute" end
        print; print "%WR;You have #{todotime} #{tempstr} in which to do something!%W;"
        write prompt
        warned = true
      end
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
   
    out    = parse_c(line.to_s)
    @socket.write parse_celerity(out)
  end 

  # Write line with CR 
  def print(line = '') 
    line = parse_c(line.to_s.gsub("\n","#{CRLF}"))
    @socket.write(parse_celerity(line) + CRLF)
  end

  def existfileout (filename,offset,override)
    GraphFile.new(self, filename, override).existfileout(offset)
  end

  def ogfileout (filename,offset,override)
    GraphFile.new(self, filename, override).ogfileout(offset)
  end

  def fileout (filename)
    GraphFile.new(self, filename).fileout(filename)
  end

  def gfileout(filename)
    GraphFile.new(self, filename).gfileout
  end
end # class Session
