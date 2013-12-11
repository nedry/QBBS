require 'messagestrings.rb'
#require "consts.rb"
require 'tools.rb'
require  'chat/irc'

class Session

  def random(r)
    # assume r is a range of integers first < last
    # this def by Mike Stok [mike@stok.co.uk] who deserves credit for it
    r.first + rand(r.last - r.first + (r.exclude_end? ? 0 : 1))
  end

  def header
    print
    if !existfileout('irchdr',0,true) then
      print "%G;Welcome to QUARKirc v1.1 You are in the %C;#{@irc_channel} %G;channel."
      print "%G;Type %Y;? %G;for Help  %Y;/QUIT %G;to Quit\r\n"
    end
  end


  def teleconference(channel)
    print ""
    quit = false
    count = 0
    game = false

    @who.user(@c_user.name).where="Teleconference (irc)"
    @irc_client = IRC::Client::new(IRCSERVER, IRCPORT)
    IRC::Event::Ping.new(@irc_client)
    @chatbuff.clear
    check_user_alias

    @irc_alias = @c_user.alias
    if channel then
      ircchannel = channel
    else
      ircchannel = IRCCHANNEL
    end
    @irc_channel = ircchannel

    @irc_client.login(@c_user.alias, @c_user.alias, "8", "*", "Telnet User")
    loop do
      count +=1
      return if count > 30

      m = @irc_client.isdata ? @irc_client.getline : nil
      if m then
        if m.kind_of? IRC::Message::ServerNotice then
           print "%Y;#{m.params}" if IRC_DEBUG

        elsif m.kind_of? IRC::Message::Numeric then
          case m.command
          when IRC::ERR_NICKNAMEINUSE
            print "%Y;*** Nickname already in use." 
            new_alias = "#{@c_user.alias}#{random(1..999)}"
            print "%Y;*** Trying #{new_alias}" 
            @irc_client.login(new_alias, @c_user.alias, "8", "*", "Telnet User")
          when IRC::RPL_CREATED
            (/^:(.*):(.*):(.*)/) =~ m.message
            print "%Y;*** #{$2}:#{$3}" if IRC_DEBUG
          when IRC::RPL_LUSEROP
            (/^:(\S*)\s(\d*)\s(\S*)\s(\d*)\s:(.*)/) =~ m.message
            print "%Y;*** There are #{$4} #{$5}" if IRC_DEBUG
          when IRC::RPL_LUSERCHANNELS
            (/^:(\S*)\s(\d*)\s(\S*)\s(\d*)\s:(.*)/) =~ m.message
            print "%Y;*** There are #{$4} #{$5}" if IRC_DEBUG
          else
            (/^:(\S*)\s(\S*)\s(\S*)\s(.*)/) =~ m.message
            out = $4
            hippy = (/^:(.*)/) =~ out
            out = $1 if !hippy.nil?
            print "%Y;*** #{out}" if IRC_DEBUG
          end
        end

        if m.command == IRC::RPL_ENDOFMOTD || m.command == IRC::ERR_NOMOTD then
          @irc_client.join(ircchannel)
          loop do
            m = @irc_client.getline
            break if m.command == IRC::RPL_ENDOFNAMES
          end
          break
        end
      else
        sleep(1)
      end
    end


    prompt = "%G;>%W;"
     header
    print "%W;"
    while true
      getinp(nil,:chat) {|l|
        line = l.strip
        out =  line.gsub("/","").to_s.upcase
        test = (/^\/(.*)/) =~ line
        if test then
          happy = (/^\/(\S*)\s(.*)/) =~ line
          out = $1.to_s.upcase if happy
            case out 
              when "NICK"
                 @irc_client.nick($2)
               when "JOIN"
                 @irc_client.join($2)
               when "MOTD"
                 #@irc_client.motd(@irc_channel)
                 @irc_client.send("MOTD")  #irc system motd command seems to be broken.  fix me!
               when "VERSION"
                 @irc_client.version(IRCSERVER)
               when "TIME"
                 #@irc_client.time(IRCSERVER)
                 @irc_client.send("TIME")
              when "TOPIC"
                 @irc_client.topic(@irc_channel,$2 )
                  print "%Y;*** Topic Changed%W;"
               when "NAMES"
                  @irc_client.send("NAMES")
               when "LIST"
                  @irc_client.send("LIST")
                when "ME"
                  @irc_client.me(@irc_channel,$2)
                  print "%Y;*** Action Sent%W;"
                when "WHOIS"
                  @irc_client.whois($2)
               when "PAGE"
                  page
               when "U"
                 displaywho
               when "MSG"
                 doit = (/^\/(\S*)\s(\S*)\s(.*)/) =~ line
                 @irc_client.privmsg($2,$3) if doit
                when "QUIT"
                  @irc_client.quit($2)
                  @irc_client.shutdown
                  @irc_cleint = nil
                  return
              end #of case
       else
          if line =="?" then
            gfileout("chatmnu")
          else
            if line
              g_test = (/(\S*)(.*)/) =~ line
              cmd = g_test ? $1.upcase : ""
              @irc_client.privmsg(@irc_channel,line)
            end
        end
      end
      #i changed this from print to write to prevent an extra cr.  I don't know why this should be?
       if !@chatbuff.empty? then
        @chatbuff.each {|x| write parse_ircc(x.strip,@c_user.ansi,true) 
        }
        @chatbuff.clear

      end
      }
    end
  end

  def check_user_alias
    if @c_user.alias.nil? then
      @c_user.alias = defaultalias(@c_user.name)
      update_user(@c_user)
      print <<-here
      %R;You have not selected a chat alias!
      %G;You have been assigned the default alias of %Y;#{@c_user.alias}
      %G;This can be changed from the user configuration menu [#%Y;%%G;]
      here
      return false
    end
    return true
  end
end
