#
# Full Screen EDitor (FSED) for QUARKware QBBS.
#
# Copyright (C) 2002, Dossy <dossy@panoptic.com>
# All rights reserved.
#
# $Id: fsed.rb,v 1.1 2002/09/12 12:27:16 dossy Exp $
#

require 'term/ansicolor'

module Editors
  module FSED
    VERSION = "0.75"
    ESC = 27.chr
    RETURN = 10.chr

    class Buffer
      def initialize(max_lines, in_file)
        @max_lines = max_lines
				@buffer = read_from_file(in_file)
      end

      def row(y)
        # indexing rows from 1
        @buffer[y - 1]
      end

      def ensure_row(y)
        @buffer[y - 1] ||= []
      end

      def []=(x, y, value)
        ensure_row(y)
        row(y)[x - 1] = value
      end

      def [](x, y)
        if row(y).nil?
          nil
        else
          row(y)[x - 1]
        end
      end

      def clear
        @buffer = []
      end

      def length
        @buffer.length
      end

      def delete_at(x, y)
        if row(y)
          row(y).slice!(x - 1)  # used to use delete_at but that didn't always work.
        end
      end

      def insert_line_at(y,ln)
       @buffer[y+1] = []  if @buffer[y+1] == nil
       @buffer.insert(y,ln)   
     end
		 
      def insert_at(y, x, chars)
        if chars
          row(y).insert(x, chars).flatten!
        end
      end

      def insert_line(y, chars)
        ensure_row(y)
        @buffer.insert(y, chars)
      end

      def delete_line_at(y)
        @buffer.delete_at(y - 1)    
      end

      def split_line_at(y, x)
        chars = delete_to_end(y, x)
        insert_line(y, chars)
      end

      def buffer_length
        return @buffer.length
      end

      def line_length(y)
        if row(y)
          return row(y).length
        else
          return 0
        end
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
        str = row(y).slice!(-(total),total)
        return str
      end

      def delete_to_end(y, x)
        row(y).slice!(x..-1)
      end

      def insert_char(x, y, value)
        ensure_row(y)
        row(y).insert(x-1,value)
      end

      def find_first_space(y)
        return row(y).index(" ")
      end

      def find_nearest_space(y,space)
        result = nil
        ensure_row(y)
        highest = 0
        row(y).each_with_index {|c,i|
          highest = i
          result = i	 if (c == " ") and (i <= space) 
        }
        result= highest if highest <= space
        return result
      end 

      def paragraph_up(start_y,width)
        for i in start_y..@buffer.length #- 1
          break if @buffer[i,0].nil? 
          pos = line_length(i-1)
          space = width - pos #how much space on the line above?
          unwrap_space = find_nearest_space(i,space)
          break if unwrap_space.nil? or unwrap_space == 0
          unwrap_str = del_range(i,0,unwrap_space+1)
          insert_at(i - 1,pos,unwrap_str)
        end
      end

      def wrap_to_width(y, width)
        ensure_row(y)
        line = row(y)

        if line[width] then # is there a character past max_width
          # if there is a space, break on it, else break the line arbitrarily
          # at _width_ ( TODO: add hyphenation if this happens )
          l_space = line[0..width].rindex(' ')

          if !l_space
            l_space = width - 1
          end
          wrap = delete_to_end(y, l_space + 1)
          # if we are on the last row, add a row for the spillover,
          # otherwise prepend to the next row and cascade-wrap

          if y == buffer_length
            insert_line(y, wrap)
          else
            insert_at(y + 1, 0, wrap)
            wrap_to_width(y + 1, width)
          end
          return wrap.length # so we know where to move the cursor
        end
      end

      def str_of_line(line)
        line ? line.collect {|c| c.nil? ? " " : c}.join("").chomp : ""
      end

      def line(line)
        str_of_line(row(line))
      end

      def buff_out
        @buffer.collect {|line| str_of_line(line) + "\n" }
      end

      def dump
        buff_out.join("").chomp
      end

      def to_s(top_start,vp_height)
        # see if we have enough lines in to print the whole buffer
        top_stop = [@buffer.length - 1, vp_height + top_start - 1].min

        (top_start .. top_stop).map {|i|
          str_of_line(@buffer[i]) + "\n"
        }.join("")
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

      def read_from_io(io)
        @buffer = []
        io.each {|line|
          line.gsub!(/[\n\r]/,"")
          @buffer << line.split(//)
        }
      end
			

      def read_from_file(filename)
        # if the filename is invalid, return an empty buffer rather than complain

        unless filename and File.exists?(filename)

          return []
        end
				file_array =[]
        IO.foreach(filename) {|line|
          line.gsub!(/[\n\r]/,"")
          file_array << line.split(//)
					}

       return file_array
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



      def open_error_log
        $lf = File.new("debug.txt", File::CREAT|File::TRUNC|File::RDWR, 0644)
      end

      def current_x
        @current_cursor_position[0]
      end

      def current_y
        @current_cursor_position[1]
      end

      def current_line
        current_y + @buffer_top
      end

      def line_end
        @buffer.line_length(current_line) - 1
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
        down = @buffer.buffer_length - current_line
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
        end_line = @buffer.line_length(current_y)+1
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
        out << parse_c("%YCTRL + e%YX%Wit %Y|%W %YG%W Help %Y|%W %YS%Wave %Y|%W %YN%Wewline %Y|%W %YY%W Delete %Y|%W #{out_str} %Y|%W Line: #{current_line}".fit(79)) << "\n"
        out << bg("black") << fg("WHITE")
        return out
      end

      def redraw(force)
        if force or @dirty
          @dirty = false
          [clear_screen,
            header,
            buffer.to_s(@buffer_top,@viewport_height),
            update_cursor_position].join("")
        else
          ""
        end
      end

      def clear
        @buffer.clear
      end

      def input_char_at_cursor(c)
        # are we in insert or overwrite mode?
        if @insert then
          @buffer.insert_char(current_x, current_line, c)
          wrap = @buffer.wrap_to_width(current_line, @screen_width - 1)

          if !wrap then
            move_cursor_right(1)
            return [c,NO_REDRAW]
          else
            # move to the end of the wrapped portion
            home_cursor
            move_cursor_down(1)
            move_cursor_right(wrap)
            # we don't want a character printed because we are in overflow
            return [nil,REDRAW]
          end
        else # overwrite mode
          if current_x < @screen_width then
            @buffer[current_x, current_line] = c
            move_cursor_right(1)
            return [c,NO_REDRAW]
          else
            home_cursor
            move_cursor_down(1)
            return [nil,NO_REDRAW]#
						end
        end
      end


      def newline
        l = current_line
        x = current_x - 1
        if @buffer.line_length(l) == 0 then
          @buffer.insert_line(l, nil)
          move_cursor_down(1)
        else
          @buffer.split_line_at(l, x)
          move_cursor_left(x)
          move_cursor_down(1)
        end
        @dirty = true
      end

      def deleteline
        @buffer.delete_line_at(current_y)
      end

      def backspace
        if current_x > 1  then                           #normal delete, not at BOL
          move_cursor_left(1)
          @buffer.delete_at(current_x, current_y)
        else
          if current_y > 1 then                         # delete at BOL
            if @buffer.line_length(current_y-1) == 0 then   #blank line above
              @buffer.delete_line_at(current_y-1)
              move_cursor_up(1)
            else
              @buffer.paragraph_up(current_y,@screen_width)   #move up until you hit a blank line...
              move_cursor_up(1)
              home_cursor
              move_cursor_right(@buffer.line_length(current_y))
            end
            return REDRAW
          end
        end
        return REDRAW
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

      def fg(col)
        t = Term::ANSIColor
        case col
        when %w(red green blue cyan magenta yellow black reset)
          return t.send col
        when %w(RED GREEN BLUE CYAN MAGENTA YELLOW BLACK)
          return t.bold + t.send(col.downcase)
        when 'hide'
          return "\e[?25l"
        when 'show'
          return "\e[?25h"
        else
          return ""
        end
      end

      def bg(col)
        t = Term::ANSIColor
        if %w(red green blue cyan magenta yellow black).include? col
          return t.send("on_#{col}")
        else
          return ""
        end
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
        out << w_update_cursor(idt+36,str+7)
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

      def screen_clear       
        # I don't know why.  Needs two redraws or the background color is wrong....
        out = redraw(true)
        out << redraw(true)
        return out
      end

    end #of class

    class Editor

      #Window Constants
      MESSAGE 	 = 1
      ABORT      = 2
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
				@in_file = in_file
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
          catch :done do
            Signal.trap('INT') do
              Signal.trap('INT', 'DEFAULT') # reset to default
									$lf.print "catch\n"
              #throw :done
             end
	        end


          if select([@in_io], nil, nil, 0.1) 


            c = @in_io.read(1)
      
            if @w_mode then    #We are in window mode, not edit mode...

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

