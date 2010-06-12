# Load the API.
require 'chat/irc'

class Botthread

  def initialize (irc_who,who,message,log)
    @irc_who,@who, @message, @log = irc_who,who, message, log
    @irc_bot = nil
  end

  # Wrap everything inside the IRC module.
  #module IRC

  def send_irc(user,message)
    @irc_bot.privmsg(user,message) if message != ""
  end

  def send_irc_all (message)
    @irc_bot.privmsg(IRCCHANNEL,message) if message != ""
  end

  def displayircwho(user)
    i = 0
    if @who.len > 0 then
      send_irc(user,"*** Telnet Users")
      @who.each_with_index {|w,i|
        send_irc(user,"*** #{w.node}: #{w.name} (#{w.where})")
      }
    else 
      send_irc(user, "*** No telnet users.") 
    end
    send_irc(user, "*** End of list.")
  end

  def telnetpage(from,to,message)
    if @who.user(to).nil? then
      send_irc(from,"*** Sorry, that user is not logged in (via telnet anyway)...")
      return
    end
    if !message.nil? then
      @who.user(to).page ||= Array.new #yet another linux nil check
      @who.user(to).page.push("%CIRC PAGE (%Gfrom #{from}%C): #{message}")
      send_irc(from,"***Message Sent.")
    else
      send_irc(from,"***No blank messages, please")
    end
  end

  def help (user)
    send_irc(user, "***Valid Commands:")
    send_irc(user, "***PAGE <userid>,<message> (pages a telnet user)")
    send_irc(user, "***USERS lists telnet users")
  end

  def run
    puts "-SA: Starting IRC Thread"
    @irc_bot = IRC::Client::new(IRCSERVER, IRCPORT)

    IRC::Event::Ping.new(@irc_bot)

    # Log onto the server.
    @irc_bot.login(IRCBOTUSER, IRCBOTUSER, "8", "*", "I am the BBS bot.")



    names = false
    tick = 0
    open_database

    loop do
      sleep(1) if !@irc_bot.isdata
      tick += 1
      #puts "-tick: #{tick}"

      @message.each {|x| send_irc_all(x)}
      @message.clear

      m = nil
      m = @irc_bot.getline if @irc_bot.isdata

      if tick == 30 then 
        tick = 0
        @irc_bot.names(IRCCHANNEL)
        names = true
        @irc_who.clear
      end

      if !m.nil? then
        #puts "BOT: #{m.message}"
        if m.is_a? IRC::Message::Numeric then
          if m.command == IRC::RPL_NAMREPLY then

            (/^:(\S*)\s(\d*)\s(\S*)(.*):(.*)/) =~ m.message 
            channel = $4; users = $5

            happy = (/=(.*)/) =~ channel
            channel = $1 if !happy.nil?

            if !users.nil?
              user_arr = users.split(" ")
              delete_irc_t
              user_arr.each {|x| @irc_who.append(Airc_who.create("*#{x}",channel))
                add_who_t(DB_who_T.new(true,0,"*#{x}",channel,"Chat (IRC)",""))                             

              }
            end
          end
          if m.command == IRC::RPL_ENDOFNAMES
            names = false 
          end
        end

        if m.command == IRC::RPL_ENDOFMOTD || m.command == IRC::ERR_NOMOTD
          @irc_bot.join(IRCCHANNEL)
          @irc_bot.oper(IRCOPERID,IRCOPERPSWD)
          @irc_bot.mode("#{IRCCHANNEL} +o #{IRCBOTUSER}")
          @irc_bot.mode("#{IRCBOTUSER} +F")
          #  @irc_bot.topic(IRCCHANNEL,IRCTOPIC)
        end

        if m.kind_of? IRC::Message::Private then
          if m.dest == IRCBOTUSER then
            instr = m.params.to_s.upcase
            happy = (/^(\S*)\s(.*)/) =~ instr
            instr = $1 if !happy.nil? 
            case instr
            when "?"
              help(m.sourcenick)
            when "USERS"
              displayircwho(m.sourcenick)
            when "PAGE"
              happy = (/^(\S*)\s(.*),(.*)/) =~ m.params
              telnetpage(m.sourcenick,$2,$3)  if !happy.nil? 
            else
              send_irc(m.sourcenick,"I'm afraid I can't do that, #{m.sourcenick}.")
              send_irc(m.sourcenick,"Why don't you sit down, take a stress pill, and type ? for help.")
            end
          end
        end
      end

    end # loop do
  end #IRC.run
end
