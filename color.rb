require 'term/ansicolor'
     def open_error_log
        $lf = File.new("color.txt", File::CREAT|File::TRUNC|File::RDWR, 0644)
      end

def print_colors
	open_error_log
       @c = Term::ANSIColor
       $lf.print "bold: #{@c.bold}\n"
       $lf.print "red: #{@c.red}\n"
       $lf.print "green: #{@c.green}\n"
       $lf.print "blue: #{@c.blue}\n"
       $lf.print "cyan: #{@c.cyan}\n"
       $lf.print "magenta: #{@c.magenta}\n"
       $lf.print "yellow: #{@c.yellow}\n"
       $lf.print "black: #{@c.black}\n"
       $lf.print "on_green: #{@c.on_green}\n"
       $lf.print "on_red: #{@c.on_red}\n"
       $lf.print "on_blue: #{@c.on_blue}\n"
       $lf.print "on_cyan: #{@c.on_cyan}\n"
       $lf.print "on_magenta: #{@c.on_magenta}\n"
       $lf.print "on_yellow: #{@c.on_yellow}\n"
       $lf.print "on_black: #{@c.on_black}\n"
       $lf.print "on_white: #{@c.on_white}\n"
       $lf.print "reset: #{@c.reset}"
      
 end
 
 print_colors