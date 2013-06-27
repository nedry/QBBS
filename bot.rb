# Load the API.
require 'chat/irc'
require 'rbconfig'
require 'cgi'
require "db/db_class.rb"
  require "rbot/r_timer"
require "rbot/r_message"

require "rbot/r_config"
require "rbot/r_config-compat"
require "rbot/r_utils"
require "rbot/r_extends"


	
class Object

  # We extend the Object class with a method that
  # checks if the receiver is nil or empty
  def nil_or_empty?
    return true unless self
    return true if self.respond_to? :empty? and self.empty?
    return false
  end

  # We alias the to_s method to __to_s__ to make
  # it accessible in all classes
  alias :__to_s__ :to_s
end


class Array  #compatiblity with r_bot plugins
   def pick_one
		self[rand(self.length)] 
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

  
  
end

require "wrap"

class Botthread


    
   require "rbot/r_plugins"
   require "rbot/rregistry"
   require "rbot/r_wrap"
   require  "rbot/r_load-gettext"
 

  def initialize (irc_who,who,message,debuglog)
     @irc_who,@who, @message = irc_who,who, message
     @plugins = Plugins::manager
     $botpassthru = self   #for shame.  using this to get 
     @plugins.scan
     @registry = BotRegistry.new self
     @debuglog = debuglog

  end
  

 
def send_me(where, message) #compatiblity with r_bot plugins
    where = IRCCHANNEL if where.nil?
    @flood_delay = 0
    #split lines longer than 400 char into mulitipile lines.  limit is 512 so this gives us some margin
    output = doWrap(message.to_s.gsub(/[\r\n]+/, "\n"),400)
    output.each_line { |line|
      line.chomp!
      sleep (@flood_delay)
      
      next unless(line.length > 0)
       send_irc(where,line)
       @flood_delay = 1 + line.length/100
    }
  end
  
  def who #compatiblity with r_bot plugins  def who  # expose bbs who list to plugins
    @who
  end
  
  def myself
    IRCBOTUSER
  end


  def nick #compatiblity with r_bot plugins
    IRCBOTUSER
  end
  


  
    
   def delegate_privmsg(message) #compatiblity with r_bot plugins
    [@plugins].each {|m|
       if m.privmsg(message)
         break
      end
    }
  end
  
  def delegate_join(message)
   [@plugins].each {|m| m.irc_delegate(:join,message)}
end
  
  def send_irc(user,message)
    @irc_bot.privmsg(user,message) if message != ""
  end

  def send_irc_all (message)
    @irc_bot.privmsg(IRCCHANNEL,message) if message != ""
  end

  def help(topic=nil)
    topic = nil if topic == ""
    case topic
    when nil
      helpstr = _("help: ")
      helpstr += @plugins.helptopics
      helpstr += _(" (help <topic> for more info)")
    else
      unless(helpstr = @plugins.help(topic))
        helpstr = _("no help for topic %{topic}") % { :topic => topic }
      end
    end
    return helpstr
  end
  
 #
  def run
   begin
    @debuglog.push("-BOT: Starting up...")
    add_log_entry(L_MESSAGE,Time.now,"IRC Bot thread starting.")
    @irc_bot = IrcBot.new(IRCSERVER, IRCPORT)

    IRC::Event::Ping.new(@irc_bot)

    # Log onto the server.
    @irc_bot.login

    names = false
    tick = 0

    loop do
      sleep(5) if !@irc_bot.isdata
      tick += 1

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
        if m.kind_of? IRC::Message::Join then
		instr = m.message.to_s
            happy = /^:(\S*)\!(.*)/ =~ instr
	  if happy then 
		mess = JoinMessage.new(self,nil,$1,m.params.to_s,nil)
		delegate_join(mess)
		end
	end
        if m.kind_of? IRC::Message::Private then
          if (m.dest ==  IRCCHANNEL) or (m.dest == IRCBOTUSER)  then
            instr = m.params.to_s
            happy = /^\!(.*)/ =~ instr
            if happy then 

            mess = PrivMessage.new(self,nil,m.sourcenick,m.dest,$1)
            cmdline = $1 
           delegate_privmsg(mess)


           deporter = /^(\S*)\s(.*)/  =~ cmdline
           cmd =cmdline
           param = nil
           if deporter then
             cmd = $1
             param = $2
           end
            dest = m.dest
            dest = m.sourcenick if m.dest == IRCBOTUSER  #send  to the right place, baby!  
            
            case cmd.downcase
               when "help"
                 send_me(dest,help($2)) 
                when "version"
                  send_me(dest, "QBBS Bot v.5... With many thanks to Rbot... http://ruby-rbot.org")
             end
          end
          end
        end
      end
    end # loop do
    rescue Exception => e
      add_log_entry(L_ERROR,Time.now,"Bot TC E:#{$!}")
      @debuglog.push("-ERROR: Bot Thread Crash. Disconnect? #{$!}")
      @debuglog.push(e.backtrace.map { |x| x.match(/^(.+?):(\d+)(|:in `(.+)')$/);
     [$1,$2,$3]
      })

      if BOT_RECONNECT_DELAY > 0 then
	@debuglog.push("-BOT: thread restart in #{BOT_RECONNECT_DELAY} seconds.")
         add_log_entry(L_MESSAGE,Time.now,"Bot thread restart in #{BOT_RECONNECT_DELAY} seconds.")
         sleep(BOT_RECONNECT_DELAY)
         retry
      end
      end
      
  end #IRC.run
end
