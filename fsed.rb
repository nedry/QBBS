#
# Full Screen EDitor (FSED) for QUARKware QBBS.
#
# Copyright (C) 2002, Dossy <dossy@panoptic.com>
# All rights reserved.
#
# $Id: fsed.rb,v 1.1 2002/09/12 12:27:16 dossy Exp $
#

module Editors
  module FSED
    VERSION = "0.7"
    ESC = 27.chr
    RETURN = 10.chr

    class Buffer
      def initialize(max_lines,in_file)
        @buffer = getfile(in_file)
        @max_lines = max_lines
      end

      def []=(x, y, value)
        if @buffer[y - 1] == nil
          @buffer[y - 1] = []
        end
        @buffer[y - 1][x - 1] = value
      end

      def [](x, y)
        if @buffer[y - 1].nil?
          nil
        else
          @buffer[y - 1][x - 1]
        end
      end
      
      def clear
        @buffer = []
end

 def length
	@buffer.length
end
      
      def delete_at(x, y)
        unless @buffer[y - 1].nil?
          @buffer[y - 1].delete_at(x - 1)
        end
      end

      def insert_at_line(y,x,in_str)
       inthing = nil 
       if !in_str.nil? then
        in_str.each_with_index {|c,i| @buffer[y-1].insert(x+ i,c)} 
       end
      end
       
      def insert_line_at(y,ln)
       @buffer[y] = []  if @buffer[y] == nil
       @buffer.insert(y,ln)   
     end
     
     def delete_line_at(y)
       @buffer.delete_at(y - 1)    
     end
     
     def buffer_length

      return @buffer.length
     end

  
     def length_y(y)
       if !@buffer[y - 1].nil?
	      return @buffer[y - 1].length
       else
	      return 0
       end
     end
  
    def del_range(y,x1,x2)
     total = x2 - x1
     str = @buffer[y-1].slice!(-(total),total)
     return str
    end
    
      def insert_char(x, y, value)
       @buffer[y - 1] = []  if @buffer[y - 1] == nil
        if (x-1) > @buffer[y-1].length then
	  @buffer[y-1] << value
	else
        @buffer[y - 1].insert(x-1,value)
	end
      end

    def find_first_space(y)
       return @buffer[y-1].index(" ")
    end

    def find_nearest_space(y,space)
       result = nil
       @buffer[y - 1] = [] if @buffer[y - 1].nil? 
       highest = 0
      @buffer[y-1].each_with_index {|c,i| 
						   highest = i
               result = i	 if (c == " ") and (i <= space) 
						   }
       result= highest if highest <= space
      return result
    end 
    
     def paragraph_up(start_y,width)
       
       for i in start_y..@buffer.length #- 1
	      if @buffer[i,0].nil? then
	       break 
	      end
	      pos = length_y(i-1)
	      space = width - pos #how much space on the line above?
	      unwrap_space = find_nearest_space(i,space)
        break if unwrap_space.nil? or unwrap_space == 0
	      unwrap_str = del_range(i,0,unwrap_space+1)
        insert_at_line(i - 1,pos,unwrap_str)
	    end
     end
 
    def detect_and_wrap(y,x,width)
      l_space = 0; wrap = nil
      @buffer[y - 1] = [] if @buffer[y - 1].nil? 
      l  = @buffer[y-1].length - 1
      test = @buffer[y-1]
     
      if !@buffer[y-1][width].nil? then #is there now a character past max_width
       test.slice!(-1)  if test.last == " "
       l_space = test.rindex(' ') 
       wrap = @buffer[y-1][l_space..l]
       del_range(y,l_space+1,l+1)
       return [l_space,wrap]
      end
    end
  
      def line(line)
        if !@buffer[line - 1].nil? then  #protect against backspace on an empty line -- produces a nil
        @buffer[line - 1].collect { |char|
          if char.nil?
            " "
          else
            char
          end
        }.to_s.chomp
       end
     end
     
     def buff_out
          @buffer.collect { |line|
          if line.nil?
            "\n"
          else
            [ line.collect { |char|
              if char.nil?
                " "
              else
                char
              end
            }, "\n" ].to_s
          end
        }
      end

     
     def dump
          @buffer.collect { |line|
          if line.nil?
            "\n"
          else
            [ line.collect { |char|
              if char.nil?
                " "
              else
                char
              end
            }, "\n" ].to_s
          end
        }.to_s.chomp
      end

      
     def to_s(top_start,vp_height)

     out = String.new
     top_stop = @buffer.length - 1
     top_stop = vp_height + top_start - 1 if @buffer.length - 1 >= vp_height + top_start
     
       for i in top_start..top_stop
        one_line = @buffer[i].to_s
        out = out+ one_line + "\n"
        end
        out
      end

def room_on_line(y,str,width)

room = false

 if !@buffer[y].nil? 
  
 if !str.nil? then
   room = true  if (@buffer[y].length - 1) + str.length < width 
end
end
return room
end

    def getfile(filename)
   file_array = []
   if !filename.nil? then
   #this used to use chars.to_a but it didn't always work right
    if File.exists?(filename) 
     IO.foreach(filename) { |line|
     line.gsub!("\n","")
     line.gsub!("\r","")  
     build = []
     for i in 0..line.length-1
      build << line[i].chr
     end
     file_array << build}
    end
   end
    puts
    file_array
   end

 end

    class EditorState
      attr_reader :current_cursor_position, :previous_cursor_position
      attr_reader :screen_width, :screen_height
      attr_reader :viewport_width, :viewport_height
      attr_reader :header_height
      attr_reader :buffer

      def initialize(width, height,in_file)
        @dirty = true
        @current_cursor_position = [1, 1]
        @previous_cursor_position = [1, 1]
        @screen_width = width
        @screen_height = height
        @buffer = Buffer.new(500,in_file)
        @buffer_top = 0
  
        @header_height = 2
        @viewport_width = @screen_width
        @viewport_height = @screen_height - @header_height
        @wrapped = false
	@insert = true

        open_error_log
      end
      
      require "windows.rb"
      
      def open_error_log
        $lf = File.new("debug.txt", File::CREAT|File::TRUNC|File::RDWR, 0644)
      end
      
      def current_x
        @current_cursor_position[0]
      end

      def current_y
        @current_cursor_position[1]
      end


      def place_cursor(x, y)
        @previous_cursor_position = @current_cursor_position
        @current_cursor_position = [x, y]
        @dirty = true
      end

      def move_cursor_up(x)
	     result = NO_REDRAW
       new_y = current_y - x
       if new_y < 1 then
        new_y = 1
 	      @buffer_top -=x if @buffer_top > 0
	      result = REDRAW
	     end
        place_cursor(current_x, new_y)
	      return result
      end

      def page_up
	     redraw = move_cursor_up(@viewport_height)
	     return redraw
      end

      def move_cursor_down(x)
	      result = NO_REDRAW
        new_y = current_y + x
        @wrapped = false
        if new_y >=@viewport_height  then
	       new_y = (current_y) 
	       @buffer_top += x
	       result = REDRAW
        end
        place_cursor(current_x, new_y)
	     return result
      end

      def page_down
	     down = @buffer.buffer_length - (current_y+ @buffer_top)  
	     if down > @viewport_height then 
	      redraw = move_cursor_down(@viewport_height)
	      return redraw
	     else
	      return NO_REDRAW
	     end
      end
      
      
      def move_cursor_left(x)
        new_x = current_x - x
        new_x = 1 if new_x < 1
        place_cursor(new_x, current_y)
      end

      def home_cursor
	      place_cursor(1,current_y)
      end 

      def move_cursor_right(x)
        new_x = current_x + x
        new_x = @viewport_width if new_x > @viewport_width
        place_cursor(new_x, current_y)
      end

  def end_cursor
   end_line = @buffer.length_y(current_y)+1
   end_line = @viewport_width if end_line > @viewport_width
	 place_cursor(end_line,current_y)
  end 

  def clear_screen
   "#{ESC}[2J#{ESC}[H#{ESC}[00m"
  end

  def toggle_ins
   @insert = !@insert
  end

	def parse_c(line)
	 COLORTABLE.each_pair {|color, result| line.gsub!(color,result) }
         return line
	end
	
  def header
   out_str = "INS"
	 out_str = "OVR" if !@insert
	 out = String.new
	 out << parse_c("%WQuark%YEDIT #{VERSION}%W".fit(79)) +"\n"
   out << parse_c("%YCTRL + e%YX%Wit %Y|%W %YG%W Help %Y|%W %YS%Wave %Y|%W %YN%Wewline %Y|%W %YY%W Delete %Y|%W #{out_str} %Y|%W Line: #{current_y + @buffer_top}".fit(79)) << "\n" 
	 out << bg("black") << fg("WHITE")
	 return out
  end
 
      def redraw(force)
        @dirty = true if force
        if @dirty
          @dirty = false
          if force
            [clear_screen,
            header,
            buffer.to_s(@buffer_top,@viewport_height),
            update_cursor_position].to_s
          else
            ""
          end
        else
          ""
        end
      end

      def clear
        @buffer.clear
      end

# this is complicated... too complicated...



      def input_char_at_cursor(c)
       if @insert then                                        #we are in insert mode
	@buffer.insert_char(current_x,(current_y) + @buffer_top,c)
	 l_space,wrap = @buffer.detect_and_wrap(current_y,current_x,@screen_width - 1)
	 if !wrap.nil? then
          if !(current_x < @buffer.length_y(current_y) - 1) then    #no wrap... insert a character
           if (current_x + wrap.length) < @screen_width  then
            move_cursor_right(1)
           return [c,NO_REDRAW]
           else                                                           #wrap at insert at end of line
            @buffer.insert_line_at(current_y,wrap.to_s.strip!)
            home_cursor
	    move_cursor_right(wrap.length - 1)
            move_cursor_down(1)
          end
          $lf.print "I'm here...wrap line\n"
          return [nil,REDRAW]        #we don't want a character printed because we are in overflow
        end

      $lf.print "@buffer.length + wrap.length: #{@buffer.length_y(current_y) +(wrap.length + 2)}\n"
      $lf.print "@screen_width: #{@screen_width}\n"
      $lf.print "room on line: #{@buffer.room_on_line(current_y + 1,wrap,@screen_width)}\n"
      $lf.print "@buffer.length: #{@buffer.length}\n"
          if (@buffer.length_y(current_y) + (wrap.length + 2)) >= @screen_width then #wrap for insert not at end of line
		   $lf.print "in insert not at end of line...\n"
	   if @buffer.room_on_line(current_y + 1,wrap,@screen_width) then	   

	    @buffer.insert_at_line(current_y+1,0,wrap)  #subsequent words go to next line

	    $lf.print "on next existing line...\n"
	   else

	     @buffer.insert_line_at(current_y,wrap) #out of room so make a new line

	     $lf.print "on a new line...\n"
	   end
            move_cursor_right(1)
            $lf.print "done with insert before line\n"
            return [c,REDRAW]
          end
	       end
	      move_cursor_right(1)  #redraw because we are inserting...
        if (@buffer.length_y(current_y)+1) == current_x then
         return [c,NO_REDRAW]     #insert mode at eol so no redraw
        else
       return [c,REDRAW] #insert mode not at eol, so redraw
      end
    
	else
	  if current_x < @screen_width then
	   @buffer[current_x,(current_y) + @buffer_top] = c    #we are in over-write mode....
	   move_cursor_right(1)
     $lf.print "Overwrite Mode\n"
	   return [c,NO_REDRAW]
	  else
      $lf.print "I'm here...sixth return\n"
	   return [nil,NO_REDRAW]
	  end
	 end
  end


  def newline
	      
  if @buffer.length_y(current_y) == 0 then
	 @buffer.insert_line_at(current_y,nil)
	  move_cursor_down(1)
  else
    str = @buffer.del_range(current_y,current_x-1,@buffer.length_y(current_y))
	  @buffer.insert_line_at(current_y,str)
	  move_cursor_left(current_x)
	  move_cursor_down(1)
   end
    @dirty = true
  end

      
  def deleteline
	 @buffer.delete_line_at(current_y)
  end
      
      def backspace
        if current_x > 1  then                           #normal delete, not at BOL
	 $lf.print "Backspace: normal delete\n"
         move_cursor_left(1)
         @buffer.delete_at(current_x, current_y)
        else
	      if current_y > 1 then                         # delete at BOL
		$lf.print "Backspace: delete at BOL\n"
           if @buffer.length_y(current_y-1) == 0 then   #blank line above
		 $lf.print "Backspace: blank line above\n"
	          @buffer.delete_line_at(current_y-1)
	          move_cursor_up(1)
	         else
	          @buffer.paragraph_up(current_y,@screen_width)   #move up until you hit a blank line...
		  $lf.print "Backspace: nothing above?  Paragraph move up\n"
	          move_cursor_up(1)
	          home_cursor
	          move_cursor_right(@buffer.length_y(current_y))
	  end
	     $lf.print "Backspace: redraw\n"
             return REDRAW
	     
          end
  end
  $lf.print "Backspace: no redraw\n"
         return NO_REDRAW
      end

   def update_cursor_position
    "#{ESC}[#{current_y + @header_height};#{current_x}H"    
   end
      
  def w_update_cursor(x,y)
   "#{ESC}[#{y + @header_height};#{x}H"    
  end

  def w_clear
   return @c.reset
  end

  def fg(forground)
    
    out = String.new

    case forground
      when "red"
       out =  "[31m"
      when "RED"
       out  = "[;1;31m"
      when "green"
       out << "[32m"
      when "GREEN"
       out = "[;1;32m"
      when "blue"
       out  = "[34m"
      when "BLUE"
       out = "[;1;34m"
      when "cyan"
       out = "[36m"
      when "CYAN"
       out = "[;1;36m"
      when "magenta"
       out = "[35m"
      when "MAGENTA"
       out = "[;1;35m"
      when "yellow"
       out = "[33m"
      when "YELLOW"
       out = "[;1;33m"
      when "black"
       out = "[30m"
      when "BLACK"
       out = "[;1;30m"
       when "hide"
        out = "[?25l"
       when "show"
        out = "[?25h"
       when "reset"
        out = "[0m"
 
      end
  return out
 end
 
   def bg(background)

    out = String.new
    
    case background
      when "red"
       out =  "[41m"
      when "green"
       out = "[42m"
      when "blue"
       out  = "[44m"
      when "cyan"
       out = "[46m"
      when "magenta"
       out = "[45m"
      when "yellow"
       out = "[43m"
      when "black"
       out = "[40m"
      when "white"
       out = "[47m"
      end
  return out
 end
 
 
  def center(string,width,color)
   result = String.new
   outdash = ((width / 2 ) - (string.length / 2)) 
   outdash.times {result << " "}
   result << color if !color.nil?
   result << string
   (width - (outdash + string.length)).times {result << " "}
   return result
 end

  def make_window(startx,starty,width,height,forground,background,border,title)
   
   f_color = fg(forground)
   b_color = bg(background)
   bdr_color = bg(border)
   window = String.new
   
   window << w_update_cursor(startx,starty)
   window  << bdr_color
   window << center(title,width,nil)
  for i in 1..height  do
      window << w_update_cursor(startx,starty+i)
      window << bdr_color << " " << b_color
      (width - 2).times {window << " "}
      window << bdr_color << " "
      window << bg("white")  << " "  
    end
     window << w_update_cursor(startx,starty+height) << bdr_color
     width.times  {window << " "}
     window << w_update_cursor(startx+1,starty+height+1) << bg("white")
     width.times  {window << " "}
     window << w_update_cursor(startx,starty)
     
   return window
  end

 def help_window
   
   idt = 16
   str = 5
   width=58
   out = make_window(str,2,60,12,"BLACK","cyan","blue","Help Window")
   out << w_update_cursor(idt,str) << fg("yellow") << bg("cyan")
   out << "CTRL-A" << fg("white")  << " Abort Message" 
   out << w_update_cursor(idt,str+1) << fg("yellow") 
   out << "CTRL-L" << fg("white") << " Refresh Screen"   
   out << w_update_cursor(idt,str+2) << fg("yellow") 
   out << "CTRL-N" << fg("white") << " New Line"  
   out << w_update_cursor(idt,str+3) << fg("yellow") 
   out << "CTRL-X" << fg("white") << " Save (Post) Message"  
   out << w_update_cursor(idt,str+4) << fg("yellow") 
   out << "CTRL-Y" << fg("white") << " Delete Line"  
   out << w_update_cursor(idt,str+6) << fg("yellow") 
   out << "INSERT" << fg("white") << " Toggle Insert/Overwrite"  
   out << w_update_cursor(idt,str+8)
   out << "ESC to exit this window." << fg("white")
 end
 
def splash_window
   
   idt = 15
   str = 8
   width = 38
   out = make_window(idt-1,str-1,40,8,"WHITE","magenta","cyan","About")
   out << w_update_cursor(idt,str+1) <<fg("yellow")  << bg("magenta")
   out << center("QUARKedit #{VERSION}",width,fg("white"))
   out << w_update_cursor(idt,str+3)
   out << center("By Dossy and Mark Firestone",width,fg("white"))
   out <<w_update_cursor(idt+36,str+7)
   #out << fg("hide")
 end
 
 def yes_no_window(question)
   idt = 11
   str = 10
   w_width = question.length + 14
   width = w_width - 2
   out = make_window(idt-2,str-1,w_width,4,"WHITE","red","yellow","Confirm")
   out << w_update_cursor(idt+1,str+1)
   out << fg("WHITE") << bg("red")
   out << question << "(Y,n): "
 end
 
 def screen_clear       # I don't know why.  Needs two redraws or the background color is wrong....
   out = redraw(true)
   out << redraw(true)
   return out
 end
 
 end #of class

  
 


    class Editor
      
      #Window Constants
      MESSAGE = 1
      ABORT     = 2
      SAVE       = 3
      SPELL      = 4
      
      def initialize(width, height, in_io, out_io,in_file,bbs_mode)
        @state = EditorState.new(width, height,in_file)
        @in_io  = in_io
        @out_io    = out_io
	@w_mode = false
        @w_type = MESSAGE
	@supress = false
	@bbs_mode = bbs_mode
      end

      def run
        @out_io.sync = true
        @in_io.sync = false
	@out_io.print @state.screen_clear
        @out_io.print @state.redraw(true)
	@out_io.print @state.splash_window
	sleep(1)
        @out_io.print @state.redraw(true)
	@out_io.print @state.redraw(true)
        buf = nil

        while true

        if select([@in_io], nil, nil, 1) 
        c = @in_io.sysread(1)
        #c = @in_io.getc
	   #    $lf.print"c: #{c}\n"
	     #  $lf.print"c-chr: #{c[0]}\n"
	#       if @supress then   # if we are suppressing the mysterious extra linefeed... we do that here.
	   #     @supress = false
	#         c = 0.chr if c.bytes.to_a[0] = 10
	#       end
	  
         if @w_mode then    #We are in window mode, not edit mode...
      	   # $lf.print "in wmode\n"
            #$lf.print "c: #{c.upcase}"
         
	        case c
	         when "\e"      #effectively, esc this is cancel for everything
	          @w_mode = false
	          @out_io.print @state.screen_clear
	        else
			
           case @w_type
              when ABORT,SAVE
                if c.upcase == "Y" or c == RETURN then
		 print "Y"
                 @state.clear if @w_type == ABORT
                 @state.clear_screen
                sleep(2)
                 break
                else
                 @out_io.print @state.screen_clear
                 @w_mode = false
               end
            end
          end
  

	  else
      case c
      when "\cX" # exit
 	@out_io.print @state.yes_no_window("Post message... Are you sure?")
        @w_type = SAVE
	@w_mode = true   
      when "\cG","\eOP"
	@out_io.print @state.help_window
        @w_type  = MESSAGE
	@w_mode = true
      when "\cA"
 	@out_io.print @state.yes_no_window("Abort message... Are you sure?")
        @w_type = ABORT
	@w_mode = true       
      when "\cN" #insert line
	@state.newline
	@out_io.print @state.redraw(true)
       when "\cY" #delete line
	@state.deleteline
	@out_io.print @state.redraw(true)
       when "\cL" # refresh
	@out_io.print @state.redraw(true)
       when "\r","\n"
        @state.newline
        @supress = true if @bbs_mode  #telnet seems to like to echo linefeeds.  lets supress this ...
	@out_io.print @state.redraw(true)
      when "\010", "\177"
        redraw = @state.backspace
        @out_io.print "\e[#{@state.current_y + @state.header_height};1H\e[K"
        @out_io.print @state.buffer.line(@state.current_y)
        @out_io.print @state.update_cursor_position
	@out_io.print @state.redraw(true) if redraw
       when "\e" # escape
        buf = c
           else
              if buf.nil?
                chr = c.unpack("c")[0]
                if (chr >= 32 && chr <= 127)
                 out_c,redraw = @state.input_char_at_cursor(c)
                 @out_io.putc(out_c) if !out_c.nil?
		 @out_io.print @state.redraw(true) if redraw
                end
              else
                buf << c
	            #	$lf.print "buf: #{buf}\n"
                case buf
		  when "\e[H","\e[1"
		    @state.home_cursor
		    @out_io.print @state.update_cursor_position
		  when "\e[F","\e[4"
		    @state.end_cursor
		     @out_io.print @state.update_cursor_position
		  when "\e[6"
                     redraw = @state.page_down
		     @out_io.print @state.redraw(true) if redraw
		  when "\e[5"
		    redraw = @state.page_up
		    @out_io.print @state.redraw(true) if redraw
		  when "\e[2"
		        @state.toggle_ins
                  @out_io.print @state.redraw(true)
                 when "\e[A"
                   redraw = @state.move_cursor_up(1)
		               if redraw
		                @out_io.print @state.redraw(true)
                   else
                    @out_io.print @state.update_cursor_position
		               end
                   buf = nil
                  when "\e[B"
		   redraw = @state.move_cursor_down(1)
		   if redraw
                    @out_io.print @state.redraw(true)
                   else
                    @out_io.print @state.update_cursor_position
		   end
                   buf = nil
                  when "\e[D"
                   @state.move_cursor_left(1)
                   @out_io.print @state.update_cursor_position
                   buf = nil
                  when "\e[C"
                  @state.move_cursor_right(1)
                  @out_io.print @state.update_cursor_position
                  buf = nil
                else
                  if buf.size >= 3
                    buf = nil
	    end
	    end
                end
              end
            end
          end
  end
        @state.buffer
	
end

    end

  end

end

