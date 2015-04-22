#!/usr/bin/ruby

# Quarkware BBS
# Copyright (C) 2014  Mark Firestone / Fly By Night Software

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

$LOAD_PATH << "."



require "thread"
require "socket"

require "tools.rb"
require "consts.rb"
require "class.rb"
require "bot.rb"
require 'dm-core'
require 'dm-validations'
require 'dm-aggregates'
require "db/db_area"
require "db/db_bulletins"
require "db/db_message"
require "db/db_doors"
require "db/db_bbs"
require "db/db_system"
require "db/db_themes"
require "db/db_who"
require "db/db_who_telnet.rb"
require "db/db_wall.rb"
require "db/db_log.rb"
require "db/db_groups"
require "db/db_user"
require "db/db_screen"
require "db/db_bbslist.rb"
require "theme"
require "screen"



require "qwk.rb"
require "rep.rb"

class Session
  attr_accessor :c_user, :c_area, :lineeditor, :who, :logged_on,
  :cmdstack, :node

  def initialize(irc_who, who, message, debuglog, socket)
    @socket  = socket
    @irc_who = irc_who
    @who  = who
    @message = message
    @c_user  = nil     #name of current user in this session
    @node = 0 #current node
    @c_area = 1     #current message area
    @wrap     = ''     #session varible for word wrapped text
    @lineeditor = LineEditor.new   #session variable for the line editor
    @cmdstack  = Cmdstack.new   #session object for command stack
    @chatbuff = Array.new   #irc client buffer
    @irc_client = nil       #irc client object
    @irc_alias = nil      #irc alias (getting lazy here...)
    @irc_channel = nil    #I promise no more session vars!
    @message = message
    @debuglog = debuglog
  end

  require "misc.rb"
  require "io.rb"
  require "errors.rb"
  require "logon.rb"
  require "who.rb"
  require "bulletin.rb"
  require "userconf.rb"
  require "message.rb"
  require "user.rb"
  require "line.rb"
  require "email.rb"
  require "teleconference.rb"
  require "main.rb"
  require "groups.rb"
  require "nntp.rb"
  require "fortune.rb"
  require "bbslist.rb"
  require "userprofiles.rb"




  def run
    telnetsetup
    logon
    theme = get_user_theme(@c_user)
    if !@c_user.fastlogon then
      if scanformail == true  then
        emailmenu if yes("%G;Would you like to read it now #{YESNO}",true,false,true)
      end
    end
    if !@c_user.fastlogon  and !theme.zipreadonlogon then
      messagemenu (true) if yes(theme.zipread_prompt,true,false,true)
    end
    commandLoop
  end
end



class MailSchedulethread

  include Enumerable, BBS_Logger
  require 'net/ftp'



  def initialize (who,message,debuglog)
    @who  = who
    @message = message
    @idxlist = []
    @control = []
    @totalareas = 0
    @debuglog = debuglog
    #@arealist = Arealist_qwk.new
    sleep (60) if IRC_ON #give the bot thread time to start before we launch other stuff

  end


  def each_who
    @who.each_index {|i| yield @who[i].name}
  end

  def each_name_with_index
    @who.each_index {|i| yield @who[i].name, i}
  end


  require "t_pktread.rb"
  require "t_pktwrite.rb"
  require "t_bundle.rb"
  require "smtp.rb"


  def process_BBS (message)
    # TODO: modify add_bbs_list to take a hash as an argument.
    # Pass the hash to Bbslist.new()
    # Have a mapping of $1 to hash keys below - default to $1.downcase and then
    # have a case statement for any leftover keys

    name = nil
    born_date = DateTime.now
    software = nil
    sysop = nil
    email = nil
    website = nil
    number = nil
    maxrate = nil
    minrate = nil
    location = nil
    network = nil
    terminal = nil
    megs = nil
    msgs = nil
    files = nil
    nodes = nil
    users = nil
    subs = nil
    dirs = nil
    xterns = nil
    desc = nil

    for i in 0..message.length-1
      match = (/^(\S+)\:(.*)/) =~ message[i]

      case $1
      when "Name"
        name = $2.strip
      when "Birth"
        begin
          born_date = Date.parse($2.strip)
        rescue
          @debuglog.push ("-ERROR: Invalid date in BBS List Entry")
        end
      when "Sysop"
        sysop = $2.strip
      when "Software"
        software = $2.strip
      when "E-mail"
        email = $2.strip
      when "Web-site"
        website = $2.strip
      when "Number"
        if number.nil? then
          number = $2.strip
        else
          number = "#{number} | #{$2.strip}"
        end
      when "Maxrate"
        maxrate = $2.strip
      when "Minrate"
        minrate = $2.strip
      when "Location"
        location= $2.strip
      when "Network"
        if network.nil? then
          network = $2.strip
        else
          network = "#{network} | #{$2.strip}"
        end
      when "Address"
        if $2.strip.length > 0 then
          network = "#{network} [#{$2.strip}]"
        end
      when "Terminal"
        if terminal.nil? then
          terminal = $2.strip
        else
          terminal = "#{terminal}, #{$2.strip}"
        end
      when "Megs"
        megs = $2.strip
      when "Msgs"
        msgs= $2.strip
      when "Files"
        files = $2.strip
      when "Nodes"
        nodes = $2.strip
      when "Users"
        users = $2.strip
      when "Subs"
        subs = $2.strip
      when "Dirs"
        dirs = $2.strip
      when "Xterns"
        xterns = $2.strip
      when "Desc"
        if desc.nil? then
          desc = $2.strip
        else
          desc = "#{desc}|#{$2.strip}"
        end
      end


    end

    @debuglog.push ("-SA: Processing BBS: #{name}")

    if exists_bbs(name) then
      @debuglog.push ("-SA: Old record exists...deleting...")
      delete_bbs(name)
    end
    if !name.nil? then
      @debuglog.push("-SA: Adding entry: #{name}")
      add_bbslist(name,born_date,software,sysop,email,website, number, minrate,
      maxrate,location,network,terminal,megs,msgs,files,
      nodes, users, subs, dirs,xterns,desc,true)

    end
    # sleep(0.5)
  end


  def parse_text_commands(line,u_space,f_space,t_space,pf_space)

    system = fetch_system

    tspacem = t_space.to_i / 1048576

    text_commands = {

      "%U_SPACE%" => u_space,
      "%F_SPACE%" => f_space,
      "%T_SPACE%" => t_space,
      "%PU_SPACE%" =>  pf_space,


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
      "%NEWUSERS%" =>  system.newu_today.to_s,
      "%TMESSAGES%" => system_m_total.to_s,
      "%TUSERS%" => u_total.to_s,
      "%TDOORS%" => d_total.to_s,
      "%TNODES%" => NODES.to_s,
      "%TSPACEM%" =>  tspacem.to_s,
      "%TAREAS%" => a_total.to_s
    }


    text_commands.each_pair {|code, result|  line.gsub!(code,result)}
    return line
  end

  def process_only(outfile)

    u_space = disk_used_space(ROOT_PATH).to_s
    f_space = disk_free_space(ROOT_PATH).to_s
    t_space =  disk_total_space(ROOT_PATH).to_s
    pf_space = disk_percent_free(ROOT_PATH).to_s

    out = []
    if File.exists?("#{TEXTPATH}#{outfile}") then
      IO.foreach("#{TEXTPATH}#{outfile}") { |line|
        deporter = parse_text_commands(line,u_space,f_space,t_space,pf_space)
        out  << deporter.gsub("\n", "")

      }
    else
      out =  ["\n#{TEXTPATH}#{outfile} has run away...please tell sysop!\n"]
    end
    return out
  end

  def savesystemmessage(x, to, title,text)


    area = fetch_area(x)
    text << DLIM

    absolute = add_msg(to,"SYSTEM",area.number, :subject => title, :msg_text => text.join(DLIM))
    add_log_entry(5,Time.now,"SYSTEM posted msg # #{absolute}")
  end


  def update_BBS_list
    @debuglog.push("-SA: Starting BBS list update")
    @debuglog.push( "-SA: Updating Synchronet BBS list details")
    savesystemmessage(BBS_LIST_MSG_AREA, "SBL", SYSTEMNAME,process_only("bbsinfo.txt"))
    delete_all_bbs_old
    area = fetch_area(BBS_LIST_MSG_AREA)
    user = fetch_user(get_uid(BBS_LIST_USER))
    scanforaccess(user)

    pointer = get_pointer(user,BBS_LIST_MSG_AREA)
    @debuglog.push("-SA: pointer:#{pointer} pointer.lastread:#{pointer.lastread if !pointer.lastread.nil?} ")

    bbs_import(area.number,pointer.lastread).each {|msg|
      #bbs_import(area.number,0).each {|msg|
      @debuglog.push ("absolute msg: #{msg.absolute}")
      message = []
      tempmsg=convert_to_ascii(msg.msg_text)

      #some QWK/REP messages seem to use linefeeds instead of 227 char characters
      #to indicate EOL

      tempmsg.gsub!(10.chr,DLIM)

      tempmsg.each_line(DLIM) {|line| message.push(line.chop!)} #changed from .each for ruby 1.9
      process_BBS(message)
    }
    pointer.lastread = high_absolute(BBS_LIST_MSG_AREA)
    update_pointer(pointer)
  end





  def up_down_fido(idle)
    ddate = Time.now.strftime("%m/%d/%Y at %I:%M%p")
    @debuglog.push("-SCHED: Starting a Fido mail transfer #{ddate}... Idle: #{idle}")
    add_log_entry(L_SCHEDULE,Time.now,"Starting a fido transfer session.")
    total = pkt_export_run
    if total == 0 then
      write_a_ilo
    end
    unbundle
  end

  def ftptest(ftpaddress,ftpaccount,ftppassword)
    begin
      ftp = Net::FTP.new(ftpaddress)
      ftp.debug_mode = false
      ftp.passive = false
      ftp.login(ftpaccount,ftppassword)
      ftp.close
      add_log_entry(L_SCHEDULE,Time.now,"Connected via FTP. Starting QWK Export.")
      @debuglog.push("-QWK/REP: Connect to #{ftpaddress}. Starting Export")
      return true
    rescue
      @debuglog.push( "-QWK/REP: Connect Fail to #{ftpaddress}. #{$!}")
      add_log_entry(L_SCHEDULE,Time.now,"Connect Fail: #{ftpaddress}.")
      return false
    end
  end

  def up_down(idle,qwknet)

    @debuglog.push( "-SCHED: Starting a QWK transfer #{Time.now.strftime("%m/%d/%Y at %I:%M%p")}... Idle: #{idle}")
    add_log_entry(L_SCHEDULE,Time.now,"Starting a QWK transfer.")

    if ftptest(qwknet.ftpaddress,qwknet.ftpaccount,qwknet.ftppassword) or QWK_DEBUG then
      worked = Rep::Exporter.new(qwknet,@debuglog)
      worked.repexport
      if worked then
        qwkimp =  Qwk::Importer.new(qwknet,@debuglog)
        qwkimp.import
      end
    end
  end


  def doit(idle)
    up_down_fido(idle) if FIDO
    do_smtp if SMTP
    if NNTP then
      nntp_up
      nntp_down
    end
  end


  def qwk_loop(idle)

    if QWK
      fetch_groups.each {|group| qwknet = get_qwknet(group)
        if !qwknet.nil? then
          @debuglog.push("-SCHED: Starting message run for #{qwknet.name}")
          up_down(idle,qwknet)
        end
      }
    else
      @debuglog.line.push("-SCHED: QWK network transfers disabled.")
    end
  end

  def run
    begin
      #uncomment to reload from scratch.  will put this in a command
      # delete_all_bbs
      # update_BBS_list
      @debuglog.push("-SCHED: Starting Message Transfer Thread. #{Time.now.strftime("%I:%M%p %m/%d/%Y")}")


      idle = 0
      current_day = Time.now.strftime("%j")
      qwk_loop(idle)
      doit(idle)
      tick = Time.now.min.to_i
      # up_down
      ddate = Time.now.strftime("%I:%M%p %m/%d/%Y")
      while true
        @debuglog.line.push("-SCHED: Thread Pause 30 seconds:  ... #{Time.now.strftime("%I:%M%p %m/%d/%Y")} (CDay #{current_day})")
        sleep(30)
        new_day = Time.now.strftime("%j")
        if new_day != current_day then  #do daily maintenance
          @debuglog.push("-SCHED: Daily Maintenance run")
          update_BBS_list
          system = fetch_system
          system.logons_today = 0
          system.posts_today = 0
          system.emails_today = 0
          system.feedback_today = 0
          system.newu_today = 0
          update_system(system)
          current_day = new_day
          @debuglog.push( "-SA: Deleting DB Log...")
          happy = system("rm #{ROOT_PATH}log/* > /dev/null 2>&1")
          if happy then
            @debuglog.push("-SA: Success!")
            add_log_entry(L_MESSAGE ,Time.now,"DB Log Deleted.")
          else
            @debuglog.push( "-SA: Failed!")
            add_log_entry(L_ERROR,Time.now,"DB Log Delete Failure.")
          end
          @debuglog.push( "-SA: Pruning message areas")
          fetch_area_list(nil).each_with_index {|area,i|

            if area.prune > 0 then
              @debuglog.push("-SA: checking message area: #{area.name}")
              if m_total(area.number) > area.prune then
                @debuglog.push("-SA: area has #{m_total(area.number)} messages.")
                @debuglog.push("-SA: prune limit is #{area.prune}")
                stop = m_total(area.number) - area.prune
                @debuglog.push("-SA: deleting #{stop} messages.")
                first = absolute_message(area.number,1)
                last = absolute_message(area.number,stop)
                add_log_entry(L_MESSAGE ,Time.now,"%WR;Deleting #{stop} messages on #{area.name}")
                delete_msgs(area.number,first,last)
              end
            end
          }

        end
        if Time.now.min.to_i != tick then
          idle = idle + 1
          tick = Time.now.min.to_i
        end


        if idle >= QWKREPINTERVAL then
          qwk_loop(idle)
          doit(idle)
          idle = 0
        end

      end
    rescue Exception => e
      @debuglog.push("ERROR: An error occurred in QWK/REP scheduler thread died: #{$!}" )
      add_log_entry(L_ERROR,Time.now,"An error occurred in QWK/REP scheduler thread died: #{$!}")
      @debuglog.push( e.backtrace)

      if SCHED_RECONNECT_DELAY > 0 then
        add_log_entry(L_MESSAGE,Time.now,"Sched thread restart in #{SCHED_RECONNECT_DELAY} seconds.")
        sleep(SCHED_RECONNECT_DELAY)
        retry
      end
    end
  end #of def run
end #of class Schedulethread



class Happythread
  include Enumerable, BBS_Logger



  def initialize (who,message,debuglog)
    @who,  @message, @debuglog= who,  message, debuglog
    clear_who_t
  end

  def each_who
    @who.each_index {|i| yield @who[i].name}
  end

  def each_name_with_index
    @who.each_index {|i| yield @who[i].name, i}
  end

  def run
    begin
      hit = false
      curthread = Array.new
      while true
        sleep (4)
        curthread = Thread.list

        @who.each {|w|
          time = Time.now
          idle_time =   time.to_i - (w.ping)
          if (idle_time > (IDLELIMIT * 60)) and (w.ping != 0) then
            @debuglog.push("-SA Thread timeout.  Resetting account: #{w.name} thread: #{w.threadn}")
            add_log_entry(8,Time.now,"Thread timeout.  Resetting account: #{w.name} thread: #{w.threadn}")
            Thread.kill(w.threadn)
          end
        }

        each_name_with_index {|name, i|
          if !curthread.any? {|thr| @who[i].threadn == thr}
            @debuglog.push("-SA: User #{i}:#{name} has disconnected.")
            ddate = Time.now.strftime("%m/%d/%Y at %I:%M%p")
            add_log_entry(5,Time.now,"#{name} has disconnected from Telnet.")
            @who.delete(i)
            who_delete_t(name) if who_t_exists(name)
            m = "%C#{name} %Ghas just disconnected from the system."
            @who.each {|who| add_page(get_uid("SYSTEM"),who.name,"*** #{name} has just disconnected from the system.",true)}
          end
        }
      end
    rescue Exception => e
      add_log_entry(8,Time.now,"Who Thread Crash! #{$!}")
      @debuglog.push("-ERROR: Who Thread Crash.  #{$!}")
      @debuglog.push($!)
      @debuglog.push (e.backtrace)
			sleep(60)
			retry

    end
  end

end #of class happythread

class ConsoleThread
  require 'ffi-ncurses'
  require 'terminfo'
  include FFI::NCurses

  def initialize (debuglog)
    @debuglog  = debuglog
    @display_debug = true
  end

  def send_name

    wattr_set(@win, A_BOLD, 2, nil)
    start = (@width  / 2) - 30
    mvwaddstr(@win,1,start, "  ___  ____  ____ ____     ____                      _      ")
    mvwaddstr(@win,2,start, ' / _ \| __ )| __ ) ___|   / ___|___  _ __  ___  ___ | | ___ ')
    mvwaddstr(@win,3,start, "| | | |  _ \\|  _ \\___ \\  | |   / _ \\| '_ \\/ __|/ _ \\| |/ _ \\")
    mvwaddstr(@win,4,start, '| |_| | |_) | |_) |__) | | |__| (_) | | | \__ \ (_) | |  __/')
    mvwaddstr(@win,5,start, ' \__\_\____/|____/____/   \____\___/|_| |_|___/\___/|_|\___|')
    mvwaddstr(@win,@height-3,9,"CTRL + e[X]it | [D]isplay Messages | Chat [B]ell ON/OFF")
  end


  def update_debug(line)
		if line.kind_of? String then # remove null bytes
		line = line.force_encoding('UTF-8').encode('UTF-16', :invalid => :replace, :replace => '?').encode('UTF-8')
		line.gsub!(/\0/, '') 
		end
    waddstr(@inner_win, "#{line}\n")
    wrefresh(@inner_win)
    #wrefresh(@win)
  end


  def run
		bug_log = Log.new("debug_log.log")
    FFI::NCurses.initscr
    FFI::NCurses.start_color
    FFI::NCurses.curs_set 0
    FFI::NCurses.raw
    FFI::NCurses.noecho
    FFI::NCurses.keypad(FFI::NCurses.stdscr, true)

    at_exit do
			system("reset")
		end
		
    #begin
      # main_window
      flushinp

      #set up colours
      init_pair(0, Color::BLACK, Color::BLACK)
      init_pair(1, Color::RED, Color::BLACK)
      init_pair(2, Color::GREEN, Color::BLACK)
      init_pair(3, Color::YELLOW, Color::BLACK)
      init_pair(4, Color::BLUE, Color::BLACK)
      init_pair(5, Color::MAGENTA, Color::BLACK)
      init_pair(6, Color::CYAN, Color::BLACK)
      init_pair(7, Color::WHITE, Color::BLACK)

      init_pair(8, Color::BLACK, Color::BLACK)
      init_pair(9, Color::BLACK, Color::RED)
      init_pair(10, Color::BLACK, Color::GREEN)
      init_pair(11, Color::BLACK, Color::YELLOW)
      init_pair(12, Color::BLACK, Color::BLUE)
      init_pair(13, Color::BLACK, Color::MAGENTA)
      init_pair(14, Color::BLACK, Color::CYAN)
      init_pair(15, Color::BLACK, Color::WHITE)


      @height, @width = TermInfo.screen_size
      @win = newwin(22, @width - 2, 1, 1)
      #box(@win, 0, 0)
      debug_lines = @height - 10
      #  if DEBUG then
      #   @border_win = newwin(9,@width - 6,12,3)
      #  @inner_win = newwin(7, @width - 10, 13, 5)
      #  else
      @border_win = newwin(debug_lines,@width - 6,8,3)
      @inner_win = newwin(debug_lines - 2, @width - 10,9, 5)
      # end
      # wborder(@border_win, 124, 124, 45, 45, 43, 43, 43, 43)
      wattr_set(@border_win, A_BOLD, 3, nil)
      box(@border_win,0,0)
      wattr_set(@inner_win, A_BOLD, 6, nil)
      mvwaddstr(@border_win,0,2,"SYSTEM MESSAGES")
      scrollok(@inner_win, true)
      send_name

      wrefresh(@win)
      wrefresh(@border_win)
      update_debug("-QBBS Server Starting up. #{Time.now.strftime("%I:%M%p %m/%d/%Y")}")
      wtimeout(@inner_win,100)
      update_debug ("-SA: Screen size detected: #{@height} #{@width} #{debug_lines}")
      while true

        ch = wgetch(@inner_win)
        if ch > 0 then
          flushinp
          case ch
          when 24   #Control X for exit
            update_debug("-SA: Shutting Down...")
            sleep(1)
						endwin
            exit
          when 4  #Control D for Display
            case @display_debug
            when true
              update_debug("-SA: System Messages OFF!")
              @display_debug = false
            when false
              update_debug("-SA: System Messages ON!")
              @display_debug = true
            end
          end
          #   update_debug("You pressed: #{ch}")
        end
				@debuglog.each{|line| bug_log.write(line)} if DLOG 

        if @display_debug then
          @debuglog.each {|line| update_debug(line)}
          @debuglog.clear
        else
          @debuglog.clear
        end

        sleep(1)
      end

    rescue Exception => e
			FFI::NCurses.endwin
      add_log_entry(8,Time.now,"Console Thread Crash! #{$!}")
     # puts("-ERROR: Console Thread Crash.  #{$!}")
      puts($!)
      puts(e.backtrace)

			sleep(60)
		retry

    ensure
      FFI::NCurses.endwin
    end
  end

#end

class FlashPolicyServer

  def initialize(debuglog)
    @debuglog = debuglog
    @serverSocket = TCPServer.open(POLICYPORT)
  end

  def figureip(peername)
    port, ip =Socket.unpack_sockaddr_in(peername)
    ip.gsub!(/[A-Za-z\:]/,"")
    return ip
  end

  def load_policy_file
    policy = File.open("crossdomain.xml", "rb").read  if File.exists?("crossdomain.xml")
    return policy
  end

  def run
    @debuglog.push( "-SA: Starting flash policy server #{Time.now.strftime("%I:%M%p %m/%d/%Y")}...")
    policy = load_policy_file

    if policy then
      while true
        if socket = @serverSocket.accept then
          Thread.new {
            @debuglog.push("-SA: Sending Flash Policy to #{figureip(socket.getpeername)}")
            socket.puts  %Q(#{policy})
            socket.close
          }
        end
        sleep(1)
      end
    else
      @debuglog.push("-SA: No crossdomain.xml file found.  Exiting Policy Server")
    end
  end

end



class ServerSocket
  def initialize(irc_who,who,message,debuglog) #,log)
    @serverSocket = TCPServer.open(LISTENPORT)
    @debuglog = debuglog
    @who = who
    @message = message
    @irc_who = irc_who
    @logged_on = false
  end

  def run
    #    set_up_database

    add_log_entry(L_MESSAGE,Time.now,"#{VER} Server Starting. #{Time.now.strftime("%I:%M%p %m/%d/%Y")}")
    if DEBUG then
      Thread.abort_on_exception = true
      add_log_entry(L_MESSAGE,Time.now,"System running in Debug mode.")
    end
    add_log_entry(L_MESSAGE,Time.now,"QWK Transfers disabled.") if !QWK
    add_log_entry(L_MESSAGE,Time.now,"FIDO Transfers disabled.") if !FIDO
    add_log_entry(L_MESSAGE,Time.now,"IRC Bot disabled.") if !IRC_ON
    Thread.new {Happythread.new(@who,@message, @debuglog).run}
    Thread.new {Botthread.new(@irc_who,@who,@message,@debuglog).run} if IRC_ON
    Thread.new {MailSchedulethread.new(@who,@message,@debuglog).run}
    Thread.new {ConsoleThread.new(@debuglog).run}
    Thread.new {FlashPolicyServer.new(@debuglog).run} if FLASH_POL

    while true
      @debuglog.push("-SA: Starting Server Accept Thread #{Time.now.strftime("%I:%M%p %m/%d/%Y")}")

      if socket = @serverSocket.accept then
        Thread.new {
          @debuglog.push("-SA: New Incoming Connection #{Time.now.strftime("%I:%M%p %m/%d/%Y")}")
          Session.new(@irc_who,@who,@message,@debuglog,socket).run
        }
      end
    end
  end
end #class ServerSocket


