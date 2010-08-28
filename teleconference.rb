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
    print ""
    print "%G;Welcome to QUARKirc v1.0 You are in the %C;#{@irc_channel} %G;channel."
    print "%G;Type %Y;? %G;for Help  %Y;/QUIT %G;to Quit\r\n"
  end


  def teleconference(channel)
    print ""
    quit = false
    count = 0
    game = false

    @who.user(@c_user.name).where="IRC (Chat)"
    @irc_client = IRC::Client::new(IRCSERVER, IRCPORT)
    IRC::Event::Ping.new(@irc_client)
    @chatbuff.clear
    check_user_alias

    @irc_alias = @c_user.alias
    puts "@irc_alias; #{@irc_alias}"
    if channel then
      ircchannel = channel
      game = true
    else
      ircchannel = IRCCHANNEL
    end
    @irc_channel = ircchannel
    puts " @irc_channel: #{ @irc_channel}"
    puts "attemping to log in"
    @irc_client.login(@c_user.alias, @c_user.alias, "8", "*", "Telnet User")
    loop do
      count +=1
      return if count > 30

      m = @irc_client.isdata ? @irc_client.getline : nil
      if m then
        puts "i've reached the server notice get"
        if m.kind_of? IRC::Message::ServerNotice then
          print "%Y;#{m.params}"

        elsif m.kind_of? IRC::Message::Numeric then
          puts m.message
          case m.command
          when IRC::ERR_NICKNAMEINUSE
            print "*** Nickname already in use."
            new_alias = "#{@c_user.alias}#{random(1..999)}"
            print "*** Trying #{new_alias}"
            @irc_client.login(new_alias, @c_user.alias, "8", "*", "Telnet User")
          when IRC::RPL_CREATED
            (/^:(.*):(.*):(.*)/) =~ m.message
            print "%Y;*** #{$2}:#{$3}"
          when IRC::RPL_LUSEROP
            (/^:(\S*)\s(\d*)\s(\S*)\s(\d*)\s:(.*)/) =~ m.message
            print "%Y;*** There are #{$4} #{$5}"
          when IRC::RPL_LUSERCHANNELS
            (/^:(\S*)\s(\d*)\s(\S*)\s(\d*)\s:(.*)/) =~ m.message
            print "%Y;*** There are #{$4} #{$5}"
          else
            (/^:(\S*)\s(\S*)\s(\S*)\s(.*)/) =~ m.message
            out = $4
            hippy = (/^:(.*)/) =~ out
            out = $1 if !hippy.nil?
            print "%Y;*** #{out}"
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

    print ""
    prompt = "%G;>%W;"
    if game then ogfileout("gd_enter",1,true) else header end

    while true
      getinp(nil,true) {|l|
        line = l.strip
        puts line
        if game
          if line and line.upcase == "HIGH" then
            ogfileout("gd_score",1,true)
            line = nil
          end
          help = line.to_s.upcase.split

          if help[0] == "HELP"  and help.length > 1 then
            proceed = GD_HELP_TABLE[help[1]]
            if !proceed.nil? then
              ogfileout("#{GD_HELP_TABLE[help[1]]}",1,true)
              line = nil
            end
          else
            if help[0] == "HELP"
              ogfileout("gd_main",1,true)
              line = nil
            end
          end
        end
        test = (/^\/(.*)/) =~ line
        if test then
          out = $1.to_s.upcase
          happy = (/^\/(\S*)\s(.*)/) =~ line
          if happy then out = $1.to_s.upcase end
          if ["NICK" "JOIN", "MOTD", "VERSION", "TIME", "NAMES", "LIST", "WHOIS"].include? out
            @irc_client.send(out.downcase, $2)
          elsif ["TOPIC", "ME"].include? out
            @irc_client.send(out.downcase, channel, $2)
          else
            case out.upcase
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
            end
          end
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

        @chatbuff.each {|x| print parse_ircc(x)}
        @chatbuff.clear
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
