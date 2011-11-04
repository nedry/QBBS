# Load the API.
require 'chat/irc'
require "db/db_class.rb"
require "r_message"


def debug (msg) #compatiblity with r_bot plugins
    puts "-RBOT: #{msg}"
  end

  module Config  #Compatabilty with rbot plugins
  require "consts"
    def Config.datadir
      ROOT_PATH
    end

  end
    
class IrcBot < IRC::Client
  

  def initialize(server, port)
    super(server, port)

  end

  
  
  def join_channel
    join(IRCCHANNEL)
    oper(IRCOPERID,IRCOPERPSWD)
    mode("#{IRCCHANNEL} +o #{IRCBOTUSER}")
    mode("#{IRCBOTUSER} +F")
  end

  def login
    super(IRCBOTUSER, IRCBOTUSER, "8", "*", "I am the BBS bot.")
  end

  def display_telnet_users(user, list)
    if list.len == 0
      privmsg(user, "*** No telnet users.")
      return
    end

    privmsg(user, "*** Telnet Users")
    list.each_with_index {|w,i|
      privmsg(user, "*** #{w.node}: #{w.name} (#{w.where})")
    }
    privmsg(user, "*** End of list.")
  end

  def handle_unknown_command(user)
    privmsg(user, "I'm afraid I can't do that, #{user}.")
    privmsg(user, "Why don't you sit down, take a stress pill, and type ? for help.")
  end

  def telnet_page(who, from, to, message)
    if who.user(to).nil?
      privmsg(from, "*** Sorry, that user is not logged in (via telnet anyway)...")
      return
    end

    if message.nil? or message.empty?
      privmsg(from,"***No blank messages, please")
      return
    end

    who.user(to).page ||= []
    who.user(to).page.push("%CIRC PAGE (%Gfrom #{from}%C): #{message}")
    send_irc(from,"***Message Sent.")
  end

  def help (user)
    privmsg(user, "***Valid Commands:")
    privmsg(user, "***PAGE <userid>,<message> (pages a telnet user)")
    privmsg(user, "***USERS lists telnet users")
  end
end

class Botthread
  attr_reader :irc_bot
    attr_reader :nick

    
   require "r_plugins"
   require "r_registry"

  def initialize (irc_who,who,message)
    @irc_who,@who, @message = irc_who,who, message
    @irc_bot = nil
    @plugins = Plugins.new(self, ["r_plugins"])

    

  end

  def nick #compatiblity with r_bot plugins
    IRCBOTUSER
  end
  
   def delegate_privmsg(message) #compatiblity with r_bot plugins
     puts "-BOT debug delegate looking"
    [@plugins].each {|m|
     puts "looping..."
       if m.privmsg(message)
         puts "found!"
         break
      end
    }
  end
  
  def send_irc(user,message)
    @irc_bot.privmsg(user,message) if message != ""
  end

  def send_irc_all (message)
    @irc_bot.privmsg(IRCCHANNEL,message) if message != ""
  end

  
  def say(where, message, mchan="", mring=-1) #compatiblity with r_bot plugins

    if mchan == ""
      chan = where
    else
      chan = mchan
    end
    if mring < 0
      if where =~ /^#/
        ring = 2
      else
        ring = 1
      end
    else
      ring = mring
    end
    message.to_s.gsub(/[\r\n]+/, "\n").each_line { |line|
      line.chomp!
      next unless(line.length > 0)
     # unless((where =~ /^#/) # && (@channels.has_key?(where) && @channels[where].quiet))
       # sendmsg "PRIVMSG", where, line, chan, ring 
       send_irc(where,line)
      #end
    }
  end


  def run
    begin
    puts "-SA: Starting IRC Bot Thread"
    add_log_entry(L_MESSAGE,Time.now,"IRC Bot thread starting.")
    @irc_bot = IrcBot.new(IRCSERVER, IRCPORT)

    IRC::Event::Ping.new(@irc_bot)

    # Log onto the server.
    @irc_bot.login

    names = false
    tick = 0

    loop do
      sleep(1) if !@irc_bot.isdata
      tick += 1
      #puts "-tick: #{tick}"

      @message.each {|x| send_irc_all(x)}
      @message.clear

      m = nil
      m = @irc_bot.getline if @irc_bot.isdata

      if tick == 30
        tick = 0
        @irc_bot.names(IRCCHANNEL)
        names = true
        @irc_who.clear
      end

      if m then
        #puts "BOT: #{m.message}"
        if m.is_a? IRC::Message::Numeric then
          if m.command == IRC::RPL_NAMREPLY then

            /^:(\S*)\s(\d*)\s(\S*)(.*):(.*)/ =~ m.message
            channel = $4; users = $5

            happy = /=(.*)/ =~ channel
            channel = $1 if happy

            if users
              user_arr = users.split(" ")
              delete_irc_t
              user_arr.each {|x|
                @irc_who.append(Airc_who.create("*#{x}",channel))
                add_who_t(true,0,channel,"Chat (IRC)","*#{x}")
              }
            end
          end
          if m.command == IRC::RPL_ENDOFNAMES
            names = false
          end
        end

        if m.command == IRC::RPL_ENDOFMOTD || m.command == IRC::ERR_NOMOTD
          @irc_bot.join_channel
        end

        if m.kind_of? IRC::Message::Private then
          if m.dest ==  IRCCHANNEL then
            instr = m.params.to_s
            happy = /^\!(.*)/ =~ instr
            if happy then 
            mess = PrivMessage.new(self,IRCCHANNEL,IRCCHANNEL,$1)
            puts "dude: #{$1}"
         # @plugins.delegate($1,mess)
           delegate_privmsg(mess)
            puts "DEBUG: after delegate_privmsg"
            case $1
               when "help"
               puts "I'm here"
               puts @plugins.help
               puts @plugins.status
                 say(m.dest,@plugins.help)
                 say(m.dest,@plugins.status)
             end
          end

          
          end
          if m.dest == IRCBOTUSER then
            from = m.sourcenick
            instr = m.params.to_s.upcase
            happy = /^(\S*)\s(.*)/ =~ instr
            instr = $1 if happy
            case instr
            when "?"
              @irc_bot.help(from)
            when "USERS"
              @irc_bot.display_telnet_users(from, @who)
            when "PAGE"
              happy = /^(\S*)\s(.*),(.*)/ =~ m.params
              @irc_bot.telnet_page(@who, from, $2, $3) if happy
            else
              @irc_bot.handle_unknown_command(from)
            end
          end
        end
      end
    end # loop do
    rescue Exception => e
      add_log_entry(L_ERROR,Time.now,"Bot TC E:#{$!}")
      puts "-ERROR: Bot Thread Crash. Disconnect? #{$!}"
      print e.backtrace.map { |x| x.match(/^(.+?):(\d+)(|:in `(.+)')$/);
      [$1,$2,$3]
      }

      if BOT_RECONNECT_DELAY > 0 then
         add_log_entry(L_MESSAGE,Time.now,"Bot thread restart in #{BOT_RECONNECT_DELAY} seconds.")
         sleep(BOT_RECONNECT_DELAY)
         retry
      end
      end
      
  end #IRC.run
end
