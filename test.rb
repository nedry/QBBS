class ConsoleThread
  require 'ffi-ncurses'
  include FFI::NCurses
  
  def initialize (debuglog)
    @debuglog  = debuglog    
  end
  

def update_debug(line)

waddstr(@inner_win, "#{line}\n")
#wmove(@inner_win,2,0)

wrefresh(@inner_win)
wrefresh(@win)
end

  
def run
  FFI::NCurses.initscr
  FFI::NCurses.start_color
  FFI::NCurses.curs_set 0
  FFI::NCurses.raw
  FFI::NCurses.noecho
  FFI::NCurses.keypad(FFI::NCurses.stdscr, true)

begin
  @win = newwin(24, 79, 1, 1)
  box(@win, 0, 0)
  @border_win = newwin(9,75,15,3)
  @inner_win = newwin(7, 70, 16, 5)
  box(@border_win,0,0)
  scrollok(@inner_win, true)
  wrefresh(@win)
  wrefresh(@border_win)
  update_debug("-QBBS Server Starting up.")
  

  #ch = wgetch(inner_win)
  #delwin(win)
  while true
    @debuglog.each {|line| updage_debug(line)}
    @debuglog.clear
    sleep(2)    
  end

rescue => e
  FFI::NCurses.endwin
  raise
ensure
  FFI::NCurses.endwin
end
end

end
	