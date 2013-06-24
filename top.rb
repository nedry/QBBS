#!/usr/bin/ruby

   # Quarkware BBS
   # Copyright (C) 2013  Mark Firestone / Fly By Night Software
    
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
    @chatbuff = Array.new 	#irc client buffer
    @irc_client = nil 			#irc client object
    @irc_alias = nil			#irc alias (getting lazy here...)
    @irc_channel = nil		#I promise no more session vars!
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
	

 

  def run
    telnetsetup
    logon 
    if !@c_user.fastlogon then
      if scanformail == true  then 
        emailmenu if yes("%G;Would you like to read it now #{YESNO}",true,false,true)
      end
    end
    if !@c_user.fastlogon then
     messagemenu (true) if yes("%G;Would you like to perform a new message scan %W;(%G;ZIPread%W;)? #{YESNO}",true,false,true)
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
    sleep (60) if !DEBUG #give the bot thread time to start before we launch other stuff
    
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
	  
    name = nil
    born_date = nil
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
	# @debuglog.push ("#{$1} #{$2}")
	 
	  case $1
	    when "Name"
	       name = $2.strip
	    when "Birth"
	       born_date = $2.strip
	    when "Sysop"
	       sysop = $2.strip
	    when "Software"
	       software = $2.strip
	    when "E-mail"
	       email = $2.strip
	    when "Web-site"
	       website = $2.strip
	    when "Number"
	       number = $2.strip
	    when "Maxrate"
	       maxrate = $2.strip
	    when "Minrate"
	       maxrate = $2.strip
	    when "Location"
	       location= $2.strip
	    when "Network"
	        if network.nil? then
	          network = $2.strip
		else
		  network = "#{network}|#{$2.strip}"
	        end
	    when "Address"
	        @debuglog.push "NUMBER 2: #{$2} #{$2.strip.length}"
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

  def update_BBS_list
     delete_all_bbs_old
     area = fetch_area(BBS_LIST_MSG_AREA)
     # for now we will scan the whole message base.  maybe add a message pointer later?  
     # lets put in the plumbing for that.
     pointer = absolute_message(area.number,1)
     i = 1
     stop = m_total(area.number) 
     until absolute_message(area.number,i).nil?
     	  @debuglog.push ("absolute msg: #{absolute_message(area.number,i)}")
	  #sleep(10)
	  msg = fetch_msg(absolute_message(area.number,i))
	  message = []
          tempmsg=convert_to_ascii(msg.msg_text)
				
				#some QWK/REP messages seem to use linefeeds instead of 227 char characters
				#to indicate EOL
				
        tempmsg.gsub!(10.chr,DLIM)

        tempmsg.each_line(DLIM) {|line| message.push(line.chop!)} #changed from .each for ruby 1.9
	 process_BBS(message)
       i += 1
       
     end
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
     #begin

    @debuglog.push("-SCHED: Starting Message Transfer Thread.")

    update_BBS_list	    
    idle = 0
    current_day = Time.now.strftime("%j")
    qwk_loop(idle)
    doit(idle)
    tick = Time.now.min.to_i
    # up_down
    ddate = Time.now.strftime("%m/%d/%Y at %I:%M%p")
    while true
     @debuglog.line.push("-SCHED: Thread Pause 30 seconds: Current Day #{current_day}")
      sleep(30)
      new_day = Time.now.strftime("%j")
      if new_day != current_day then  #do daily maintenance
	@debuglog.push("-SCHED: Daily Maintenance run")
        system = fetch_system
        system.logons_today = 0
        system.posts_today = 0
        system.emails_today = 0
        system.feedback_today = 0
        system.newu_today = 0
        update_system(system)
        current_day = new_day
        @debuglog.push( "-SA: Deleting DB Log...")
         happy = system("rm #{ROOT_PATH}/log/*")
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
#     rescue Exception => e
 #     @debuglog.push("ERROR: An error occurred in QWK/REP scheduler thread died: #{$!}" )
 #    # add_log_entry(L_ERROR,Time.now,"An error occurred in QWK/REP scheduler thread died: #{$!}")
  #    @debuglog.push( e.backtrace.map { |x| x.match(/^(.+?):(\d+)(|:in `(.+)')$/);
   #   [$1,$2,$3]})
      
   #   if SCHED_RECONNECT_DELAY > 0 then
  #       add_log_entry(L_MESSAGE,Time.now,"Sched thread restart in #{SCHED_RECONNECT_DELAY} seconds.")
    #     sleep(SCHED_RECONNECT_DELAY)
     #    retry
     # end
   #  end
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
      print $!
      print e.backtrace.map { |x| x.match(/^(.+?):(\d+)(|:in `(.+)')$/);
      [$1,$2,$3]
      }
      
      end
  end

end #of class happythread

class ConsoleThread
  require 'ffi-ncurses'
  include FFI::NCurses
  
  def initialize (debuglog)
    @debuglog  = debuglog
    @display_debug = true
  end
  
def send_name

  mvwaddstr(@win,1,9, '  ___  ____  ____ ____     ____                      _      ')
  mvwaddstr(@win,2,9, ' / _ \| __ )| __ ) ___|   / ___|___  _ __  ___  ___ | | ___ ')
  mvwaddstr(@win,3,9, "| | | |  _ \\|  _ \\___ \\  | |   / _ \\| '_ \\/ __|/ _ \\| |/ _ \\")
  mvwaddstr(@win,4,9, '| |_| | |_) | |_) |__) | | |__| (_) | | | \__ \ (_) | |  __/')
  mvwaddstr(@win,5,9, ' \__\_\____/|____/____/   \____\___/|_| |_|___/\___/|_|\___|')
  mvwaddstr(@win,20,3,"CTRL + e[X]it | [D]isplay Messages | Chat [B]ell ON/OFF")
end


def update_debug(line)

waddstr(@inner_win, "#{line}\n")
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
 # main_window 
  flushinp
  @win = newwin(22, 78, 1, 1)
  #box(@win, 0, 0)
  #@border_win = newwin(9,74,12,3)
  #@inner_win = newwin(7, 69, 13, 5)
  
  @border_win = newwin(22,74,1,3)
  @inner_win = newwin(20, 69, 2, 5)
   wborder(@border_win, 124, 124, 45, 45, 43, 43, 43, 43)
 # box(@border_win,0,0)
  mvwaddstr(@border_win,0,2,"SYSTEM MESSAGES")
  scrollok(@inner_win, true)
  send_name

  wrefresh(@win)
  wrefresh(@border_win)
  update_debug("-QBBS Server Starting up.")
  wtimeout(@inner_win,100)
  while true

	ch = wgetch(@inner_win)
    if ch > 0 then
	flushinp
	case ch
	  when 24   #Control X for exit
	     update_debug("-SA: Shutting Down...")
	     sleep(1)
	     #put exit code here
	     FFI::NCurses.endwin
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
     if @display_debug then
        @debuglog.each {|line| update_debug(line)}
        @debuglog.clear
     else
	@debuglog.clear
     end

    sleep(1)    
  end

rescue => e
  FFI::NCurses.endwin
  raise
ensure
  FFI::NCurses.endwin
end
end

end
	
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
      @debuglog.push( "-SA: Starting flash policy server...")
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
    
    add_log_entry(L_MESSAGE,Time.now,"#{VER} Server Starting.")
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
      @debuglog.push("-SA: Starting Server Accept Thread")

      if socket = @serverSocket.accept then
        Thread.new {
          @debuglog.push("-SA: New Incoming Connection")
          Session.new(@irc_who,@who,@message,@debuglog,socket).run
        }
      end
    end
  end
end #class ServerSocket


