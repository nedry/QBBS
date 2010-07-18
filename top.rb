#!/usr/bin/ruby
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
require "db/db_who"
require "db/db_who_telnet.rb"
require "db/db_wall.rb"
require "db/db_log.rb"
require "db/db_groups"
require "db/db_user"
require "db.rb"
#require "t_pktread"
#require "t_pktwrite"

require "qwk.rb"
require "rep.rb"

class Session 
  attr_accessor :c_user, :c_area, :lineeditor, :who, :logged_on,
    :cmdstack

  def initialize(irc_who, who, message, socket)
    @socket  = socket 
    @irc_who = irc_who
    @who  = who
    @message = message
    @c_user  = nil     #name of current user in this session
    @c_area = 1     #current message area
    @wrap     = ''     #session varible for word wrapped text 
    @lineeditor = LineEditor.new   #session variable for the line editor
    @cmdstack  = Cmdstack.new   #session object for command stack
    @chatbuff = Array.new 	#irc client buffer
    @irc_client = nil 			#irc client object
    @irc_alias = nil			#irc alias (getting lazy here...)
    @irc_channel = nil		#I promise no more session vars!
    @message = message		
    @gd_game = false		#ok, just one more!
    @gd_mode = false 		#this time, I mean it.
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

  def run
    telnetsetup
    logon 
    if !@c_user.fastlogon then
      if scanformail == true  then 
        emailmenu if yes("%GWould you like to read it now #{YESNO}",true,false,true)
      end
    end
    if !@c_user.fastlogon then
     messagemenu (true) if yes("%GWould you like to perform a new message scan %W(%GZIPread%W)? #{YESNO}",true,false,true)
    end
    commandLoop
  end
end


class MailSchedulethread

  include Enumerable, Logger
  require 'net/ftp'


  def initialize (who,message)
    @who  = who
    @message = message
    @idxlist = []
    @control = []
    @totalareas = 0
    #@arealist = Arealist_qwk.new
    
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


  def up_down_fido(idle)
    ddate = Time.now.strftime("%m/%d/%Y at %I:%M%p")
    puts "-SCHED: Starting a Fido mail transfer #{ddate}... Idle: #{idle}"
    add_log_entry(L_SCHEDULE,Time.now,"Starting a fido transfer session.")
    total = pkt_export_run
    if total == 0 then
      write_a_ilo
    end
    unbundle
  end

  def ftptest
    begin
      ftp = Net::FTP.new(FTPADDRESS)
      ftp.debug_mode = false
      ftp.passive = false
      ftp.login(FTPACCOUNT,FTPPASSWORD)
      ftp.close
      add_log_entry(L_SCHEDULE,Time.now,"Connected via FTP. Starting QWK Export.")
      puts "-QWK/REP: Successfull Connection to FTP Server. Starting Export"
      return true
    rescue
      puts "-QWK/REP: Cannot connect to FTP Server. #{$!}"
      add_log_entry(L_SCHEDULE,Time.now,"Cannot connect to FTP Server.")
      return false
    end
  end

  def up_down(idle)
    puts "-SCHED: Starting a QWK/REP message transfer #{Time.now.strftime("%m/%d/%Y at %I:%M%p")}... Idle: #{idle}"
    add_log_entry(L_SCHEDULE,Time.now,"Starting a QWK/REPmessage transfer.")
    
    if ftptest or QWK_DEBUG then
      worked = Rep::Exporter.new(REPDATA)
       worked.repexport(QWKUSER)
      if worked then 
        qwkimp =  Qwk::Importer.new(nil)
        qwkimp.import
      end
    end
  end


  def doit(idle)
    up_down_fido(idle) if FIDO
    do_smtp if SMTP
    up_down(idle) if QWK

  end

  def run
    # begin
    puts "-SCHED: Starting Message Transfer Thread."
    idle = 0
    doit(idle)
    tick = Time.now.min.to_i
    # up_down
    ddate = Time.now.strftime("%m/%d/%Y at %I:%M%p")
    while true
      puts "-SCHED: Thread Pause 30 seconds"
      sleep(30)

      if Time.now.min.to_i != tick then
        idle = idle + 1
        tick = Time.now.min.to_i
      end

      #puts "Idle Time:  #{idle}"
      if idle >= QWKREPINTERVAL then
        doit(idle)
        idle = 0
      end

    end
    # rescue
    #  puts "ERROR: An error occurred in QWK/REP scheduler thread died: ",$!, "\n" 
    #  @log.line.push("%RERROR   %G: %R An error occurred in QWK/REP scheduler thread died: #{$!}")

    # end
  end #of def run
end #of class Schedulethread



class Happythread
  include Enumerable, Logger



  def initialize (who,message)
    @who,  @message= who,  message
    clear_who_t
  end

  def each_who
    @who.each_index {|i| yield @who[i].name}
  end

  def each_name_with_index
    @who.each_index {|i| yield @who[i].name, i}
  end

  def run
    hit = false
    curthread = Array.new
    while true
      sleep (4)
      curthread = Thread.list
      #  puts Thread.list.each {|x| puts x.to_s}
      each_name_with_index {|name, i|
        if !curthread.any? {|thr| @who[i].threadn == thr}
          puts "-SA: User #{i}:#{name} has disconnected."
          ddate = Time.now.strftime("%m/%d/%Y at %I:%M%p") 
          add_log_entry(5,Time.now,"#{name} has disconnected from Telnet.")
          @who.delete(i)
          who_delete_t(name) if who_t_exists(name)
          m = "%C#{name} %Ghas just disconnected from the system."
          @message.push("*** #{name} has just disconnected from the system.")
          each_who {|u| u.who.push(m)}
        end
      }
    end
  end
end #of class happythread

class ServerSocket
  def initialize(irc_who,who,message) #,log)
    @serverSocket = TCPServer.open(LISTENPORT)

    @who = who
    @message = message
    @irc_who = irc_who
    @logged_on = false
  end

  def run
    set_up_database
    
    add_log_entry(L_MESSAGE,Time.now,"#{VER} Server Starting.")
    if DEBUG then
      Thread.abort_on_exception = true 
      add_log_entry(L_MESSAGE,Time.now,"System running in Debug mode.")
    end
    add_log_entry(L_MESSAGE,Time.now,"QWK Transfers disabled.") if !QWK
    add_log_entry(L_MESSAGE,Time.now,"FIDO Transfers disabled.") if !FIDO
    add_log_entry(L_MESSAGE,Time.now,"IRC Bot disabled.") if !IRC_ON
    Thread.new {Happythread.new(@who,@message).run}
    Thread.new {Botthread.new(@irc_who,@who,@message).run} if IRC_ON
    Thread.new {MailSchedulethread.new(@who,@message).run} 

    while true
      puts "-SA: Starting Server Accept Thread";
      $stdout.flush
      if socket = @serverSocket.accept then
        Thread.new {
          puts "-SA: New Incoming Connection"
          Session.new(@irc_who,@who,@message,socket).run
        }
      end
    end
  end
end #class ServerSocket

#def replogandputs(m)
 # writereplog m
 # puts m
#end
