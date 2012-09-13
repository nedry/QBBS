require "tools.rb"
#require "consts.rb"

class Session
  def getmsglen
    @lineeditor.msgtext.nil? ? 0 : (@lineeditor.msgtext.length)
  end

  def quoter(reply_text)
    prompt = "%W;[%Y;C%W;]%G;ut/Paste %W;[%Y;L%W;]%G;ist %W;[%Y;R%W;]%G;eturn: "
    while true
      getinp(prompt) {|inp|
        happy = inp.upcase
        parameters = Parse.parse(happy)
        happy.gsub!(/[-\d]/,"")

        u = @c_user
        width = u.width - 5

        case happy
        when "L"
          cont = true
          j = 0
          len = reply_text ? reply_text.length : 0
          start, stop = getlinerange(len, parameters,true)
          write "%W;"

          if !start.nil?  and !stop.nil? then
            for i in start..stop do
              print "#{i}:  #{reply_text[i - 1]}".slice(0..width)
              j +=1
              if j == u.length and u.more then
                cont = moreprompt
                write "%W;"
                j = 1
              end
              break if !cont
            end
          end

        when "C"
          len	= reply_text.length || 0
          start, stop = getlinerange(len, parameters,false)
          if !start.nil?  and !stop.nil? then
            for i in start..stop
              @lineeditor.msgtext.push(">#{reply_text[i-1]}".slice(0..width))
            end
            print "%RW;#{(stop - start + 1)} line(s) quoted%W;"
            len = (@lineeditor.msgtext.nil?) ? 0 : @lineeditor.msgtext.length
            @lineeditor.line = len + 1
          else
            print "%RW;Aborted.%W;"
          end
        when "R"
          return
        end #of case
      }
    end
  end # of def

  def getlinerange(len, parameters,default_is_all)
    start,stop  = parameters[0..1]


    if (default_is_all) and (start == -1) then
      start = 1
      stop = len
    end

    start = 0 if start < 0

    stop = start if stop < start
    if (start == 0) then
      prompt = "Starting line (1-#{len}) or 0 to abort? "
      start = getnum(prompt,0,len)
      return [nil, nil] if (start == 0) or (start.nil?)	#this behaviour is wrong.. why?
      prompt = "Ending line (#{start}-#{len}) or 0 to abort? "
      stop = getnum(prompt,0,len) {|i| i == 0 || (start..len).include?(i)}

      return [nil, nil] if (stop == 0 ) or (stop.nil?)
    end
    return start, stop
  end

  def displaycolors
    write "%Y;"
    @socket.write "Color Codes: "
    write "%R;"; @socket.write "%R; "
    write "%r;"; @socket.write "%r; "
    write "%G;"; @socket.write "%G; "
    write "%g;"; @socket.write "%g; "
    write "%Y;"; @socket.write "%Y; "
    write "%y;"; @socket.write "%y; "
    write "%B;"; @socket.write "%B; "
    write "%b;"; @socket.write "%b; "
    write "%M;"; @socket.write "%M; "
    write "%m;"; @socket.write "%m; "
    write "%C;"; @socket.write "%C; "
    write "%c;"; @socket.write "%c; "
    write "%W;"; @socket.write "%W; "
    write "%w;"; @socket.write "%w;"
    print
    print "%G;Background Codes follow Forground Codes: "
    write "%WR; "; @socket.write "%WR% "
    write "%W; %wr;"; @socket.write "%wr;"
    write "%W; %WG;"; @socket.write "%WG;"
    write "%W; %wg;"; @socket.write "%wg;"
    write "%W; %WY;"; @socket.write "%WY;"
    write "%W; %wy;"; @socket.write "%wy;"
    write "%W; %WB;"; @socket.write "%WB;"
    write "%W; %wb;"; @socket.write "%wb;"
    write "%W; %WM;"; @socket.write "%WM;"
    write "%W; %wm;"; @socket.write "%wm;"
    write "%W; %WC;"; @socket.write "%WC;"
    write "%W; %wc;"; @socket.write "%wc;"
    write "%W; %W;"
    print
  end

  def editmenu
    print <<-here
    %W;[%Y;A%W;]%G;bort   %W;[%Y;C%W;]%G;ontinue   %W;[%Y;I%W;]%G;nsert %W;[%Y;F%W;]%G;ind (and Replace)
    %W;[%Y;D%W;]%G;elete  %W;[%Y;E%W;]%G;dit line  %W;[%Y;L%W;]%G;ist   %W;[%Y;R%W;]%G;eplace line
    %W;[%Y;T%W;]%G;itle   %W;[%Y;S%W;]%G;ave       %W;[%Y;Q%W;]%G;uote

    here
  end

  def replace_line(args)
    len = getmsglen
    replaceline = args.shift || 0

    prompt = "%Y;Replace line (1-#{len}) or 0 to abort?%W; "
    replaceline = getnum(prompt, 0, len)

    return if replaceline == 0

    list [replaceline, 0]
    if yes("%G;Replace this line #{NOYES}? %W;",false,false,false) then
      prompt = "%G;Enter new line or enter <CR> to abort:%W; "
      newline = getinp(prompt)
      if newline == "" then print "Line NOT replaced"
      else
        print "%WR;Line REPLACED.%W;"
        @lineeditor.msgtext[replaceline - 1] = newline
      end
    end
  end

  def insert_lines(args)
    len = getmsglen
    insertline = args.shift || 0

    if len >= MAXMESSAGESIZE then
      print "%WR;No more room!%W;"
      return false
    end

    insertline = getnum("%Y;Insert after which line? %W;",0,len) if
    !(1...len).include?(insertline)

    if (insertline <= len) and (insertline >= 0) then
      @lineeditor.line = (insertline + 1)
      return true
    else
      print "%WR;Invalid input!%W;"
    end
  end

  def delete_lines(parameters)
    len = getmsglen
    start, stop = getlinerange(len, parameters,false)
    return if !start
    @lineeditor.msgtext.slice!(start-1..stop-1)
    print "#{(stop - start + 1)} line(s) deleted"
    @lineeditor.msgtext.compact!
    len = @lineeditor.msgtext ? @lineeditor.msgtext.length : 0
    @lineeditor.line = len + 1
  end
	
	  def change_title(parameters,title)
		 print "%Y;Current message title is: %C;#{title}%W;"
     prompt = "%G;Enter new message title or enter <CR> to abort:%W; "
		 temp_title = getinp(prompt)
     if !temp_title.strip.nil? then
			 print "%G;Message Title changed to: %C;#{temp_title}%W;"
			 return temp_title
		 else
			 print "%WR;Aborted%W;"
			 return title
		 end

  end

  def edit_line(args)

    editline = args.shift || 0
    len = getmsglen


    if !(1..len).include?(editline)
      prompt = "%Y;Edit line (1-#{len}) or 0 to abort? %W;"
      editline = getnum(prompt,0,len)
    end
    return if editline == 0
    list ([editline, 0 ])
    oldline = getinp("%G;Enter old string: %W;")
    return if oldline == ""
    x = @lineeditor.msgtext[editline-1].index(oldline)
    print "%RW;Not found!%W;" if x == nil

    newline = getinp("%G;Enter new string: %W;")
    @lineeditor.msgtext[editline-1].sub!(oldline,newline) if newline != ''
  end

  def list(parameters)
    len = getmsglen
    start, stop = getlinerange(len, parameters,true)
    for i in start..stop do
      print "%W;#{i}:  %C;#{@lineeditor.msgtext[i - 1]}%W;"
    end
  end

  def editprompt(reply_text,title)
    @lineeditor.msgtext.compact!

    while true
      prompt = "%G;Edit (?/help): %W;"
      happy = getinp(prompt).upcase
      parameters = Parse.parse(happy)
      happy.gsub!(/[-\d]/,"")
      case happy
      when "S"; @lineeditor.save = true; return [true,title]
      when "A"; @lineeditor.save = false; return [true,title]
      when "C";	return [false,title]
      when "E"; edit_line(parameters)
      when "D"; delete_lines(parameters)
			when "T"; title = change_title(parameters,title)
      when "L"; list(parameters)
      when "R"; replace_line(parameters)
      when "I"; return [false,title] if insert_lines(parameters)
      when "?"; editmenu
      when "Q"; quoter(reply_text)
      end #of case
    end # of until

  end # of def

  def lineedit(startline,reply_text,file,title)

    print "%G;Enter message text.  %Y;#{MAXMESSAGESIZE}%G; lines maximum."
    if @c_user.ansi
      then
        displaycolors
      end
      print
      print "%WG;/EX for editor prompt, /S to save, /Q to quote, /A to abort.%W;"

      write "%C;"

      len 		= 0
      done 		= false
      workingline 	= ''
      @lineeditor.line = 1

      @cmdstack.cmd.clear			#clear the command buffer
      @lineeditor.msgtext.clear			#clear the message buffer
      
      if file then
          File.open(file, "r").each_line {|line| temp = line
          temp = temp.gsub(/\r/," ")
          temp = temp.gsub(/\n/," ")
          @lineeditor.msgtext << temp}
          @lineeditor.line = @lineeditor.msgtext.length + 1
     end


      until (done)

        until (len >= MAXMESSAGESIZE) or (done)
          prompt1 = "#{@lineeditor.line}: "
          write prompt1
          workingline = getstr(ECHO,WRAP,@c_user.width-4,prompt1,false,false)

          case workingline.upcase.strip
          when  "/A"; done = true; @lineeditor.save = false
          when "/S"; done = true; @lineeditor.save = true
          when "/Q"; quoter(reply_text)
          when "/EX"; break				#and we fall through the loop to editprompt
          else
            @lineeditor.line += 1
            offset = @lineeditor.line < len ? 2 : 0
            @lineeditor.msgtext[@lineeditor.line - offset,0] = workingline
            len = @lineeditor.msgtext.length
            if len == (MAXMESSAGESIZE - 2) then print "%WR;Two Lines Left!%W;" end
          end # of Case

        end # of Inner Until
        if !done then
          done,title = editprompt(reply_text,title)
        end
      end #of Outer until
      return [@lineeditor.save,title]
    end
  end #class Session
