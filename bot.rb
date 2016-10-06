# Load the API.
require 'chat/irc'
require 'cgi'
require "db/db_class.rb"




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
    mode("#{IRCCHANNEL} +o #{@ircbotuser}")
    mode("#{@ircbotuser} +F")
  end

#  def login
#    super(IRCBOTUSER, IRCBOTUSER, "8", "*", "I am the BBS bot.")
#  end



end

require "wrap"

class Botthread

require "PlugMan.rb"



  def initialize (irc_who,who,message,debuglog)
    @irc_who,@who, @message, @debuglog = irc_who,who, message, debuglog
  end

############################################################
# The following code is from Rbot 0.9.15

  def send_me(where, message)  
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

def doWrap(text, margin)
    output = ''
    text.each_line do #1.9 fix
      | paragraph |
      if (paragraph !~ /^>/)
        paragraph = wrapParagraph(paragraph, margin-1)
      end
      output += paragraph
    end
    return output
  end


  def wrapParagraph(paragraph, width)
    lineStart = 0
    lineEnd = lineStart + width
    while lineEnd < paragraph.length
      newLine = paragraph.index("\n", lineStart)
      if newLine && newLine < lineEnd
        lineStart = newLine+1
        lineEnd = lineStart + width
        next
      end
      tryAt = lastSpaceOnLine(paragraph, lineStart, lineEnd)
      paragraph[tryAt] = paragraph[tryAt].chr + "\r\n"
      tryAt += 2
      lineStart = findFirstNonSpace(paragraph, tryAt)
      paragraph[tryAt...lineStart] = ''
      lineStart = tryAt
      lineEnd = lineStart+width
    end
    return paragraph
  end

  def findFirstNonSpace(text, startAt)
    startAt.upto(text.length) do
      | at |
      if text[at] != 32
        return at
      end
    end
    return text.length
  end

  def lastSpaceOnLine(text, lineStart, lineEnd)
    lineEnd.downto(lineStart) do
      | tryAt |
      case text[tryAt].chr
        when ' ', '-'
          return tryAt
      end
    end
    return lineEnd
  end
	
#End
############################################################

  def send_irc(user,message)
    @irc_bot.privmsg(user,message) if message != ""
  end

  def send_irc_all (message)
    @irc_bot.privmsg(IRCCHANNEL,message) if message != ""
  end


	
PlugMan.define :main do
  author "Mark"
  version "1.0.0"
  extends(:root => [:root])
  requires []
  extension_points [:bots]
  params()
	
	def delegate(m,debuglog,who)
		      chan = nil; out = nil;
	        if m.kind_of? IRC::Message::Private then
            if (m.dest ==  IRCCHANNEL) or (m.dest == IRCBOTUSER)  then
              instr = m.params.to_s
              happy = /^\!(.*)/ =~ instr
              if happy then
								  cmd = $1.split.first(1).join(' ').downcase
							    PlugMan.extensions(:main, :bots).each do |plugin|
									out,chan = plugin.do(m,:debuglog => debuglog, :who => who) if plugin.params.has_value? (cmd)
							end
	          end
					end
          return [chan,out]
				end

	        if m.kind_of? IRC::Message::Join then
							    PlugMan.extensions(:main, :bots).each do |plugin|
									out,chan = plugin.do(m,:debuglog => debuglog, :who => who) if plugin.params.has_key? (:join)
					end
          return [chan,out]
			end

	end
		

		
	  def plugin_info(debuglog)
    debuglog.push( "-BOT: Registered plugins")
    puts
    
    # loop all the plugins in the system, sorting before we loop
    PlugMan.registered_plugins.sort do |a,b|
      a.to_s <=> b.to_s
    end.each do |k,v|
      # printout plugin information

      debuglog.push ("    Name #{k.inspect} (#{v.version}) Author: #{v.author} ")
      
      # gather the plugins connected to the plugin's extension points
      str = ""
      v.extension_points.each do |extpt|
        conn = []
        PlugMan.extensions(k, extpt).each do |pl|
          conn << pl.name.to_s
        end
        str = "#{extpt.inspect}(#{conn.join(", ")})"
      end if v.extension_points
		

    end
		
  end
	
end
  #
  def run
    begin
      @ircbotuser = IRCBOTUSER
      @debuglog.push("-BOT: Starting up...")
      add_log_entry(L_MESSAGE,Time.now,"IRC Bot thread starting.")
			@debuglog.push("-BOT: Loading Plugins")
			PlugMan.load_plugins "./botplugins"
			PlugMan.start_all_plugins
      PlugMan.registered_plugins[:main].plugin_info(@debuglog)
      @irc_bot = IRC::Client::new(IRCSERVER, IRCPORT)

      IRC::Event::Ping.new(@irc_bot)

      # Log onto the server.
      @irc_bot.login(@ircbotuser, @ircbotuser, "8", "*", "I am the BBS bot.")

      names = false
      tick = 0

      loop do
        sleep(1) if !@irc_bot.isdata
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
          @debuglog.push( "BOT: #{m.message}") if IRC_DEBUG
          if m.is_a? IRC::Message::Numeric then
				
	    if m.command ==  IRC::ERR_NICKNAMEINUSE then
		@ircbotuser = "#{IRCBOTUSER}_#{(0...3).map { (65 + rand(26)).chr }.join}"
		@irc_bot.login(@ircbotuser, @ircbotuser, "8", "*", "I am the BBS bot.")
                sleep(1)
	    end
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
          @irc_bot.join(IRCCHANNEL)
				end
				chan,out = PlugMan.registered_plugins[:main].delegate(m,@debuglog,@who)
				send_me(chan,out) if !out.nil?
				
        end
      end # loop do
    rescue Exception => e
      add_log_entry(L_ERROR,Time.now,"Bot TC E:#{$!}")
      @debuglog.push("-ERROR: Bot Thread Crash. Disconnect? #{$!}")
      @debuglog.push(e.backtrace)

      if BOT_RECONNECT_DELAY > 0 then
        @debuglog.push("-BOT: thread restart in #{BOT_RECONNECT_DELAY} seconds.")
        add_log_entry(L_MESSAGE,Time.now,"Bot thread restart in #{BOT_RECONNECT_DELAY} seconds.")
        sleep(BOT_RECONNECT_DELAY)
        retry
      end
    end

  end #IRC.run
end
