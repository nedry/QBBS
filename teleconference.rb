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
    print "%GWelcome to QUARKirc v1.0 You are in the %C#{@irc_channel} %Gchannel."
    print "%GType %Y? %Gfor Help  %Y/QUIT %Gto Quit\r\n"
  end


  def teleconference(channel)

    print ""
    quit = false
    count = 0
    game = false

    @who.user(@c_user.name).where="IRC (Chat)"
    #channel = IRCCHANNEL
    @irc_client = IRC::Client::new(IRCSERVER, IRCPORT)
    IRC::Event::Ping.new(@irc_client)
    #IRC::Event::Debug.new(@irc_client)
    @chatbuff.clear
    checkuseralias

    @irc_alias = @c_user.alias
    puts "@irc_alias; #{@irc_alias}"
    if !channel.nil? then
      ircchannel = channel
      game = true
    else ircchannel = IRCCHANNEL end
    @irc_channel = ircchannel
    puts " @irc_channel: #{ @irc_channel}"
    puts "attemping to log in"
    @irc_client.login(@c_user.alias, @c_user.alias, "8", "*", "Telnet User")
    loop do
      count +=1
      # puts "looping"
      return if count > 30
      m = nil

      m = @irc_client.getline if @irc_client.isdata
      if !m.nil? then
        puts "i've reached the server noteice get"
        if m.kind_of? IRC::Message::ServerNotice then
          print "%Y#{m.params}"

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
            print "%Y*** #{$2}:#{$3}"
          when IRC::RPL_LUSEROP
            (/^:(\S*)\s(\d*)\s(\S*)\s(\d*)\s:(.*)/) =~ m.message
            print "%Y*** There are #{$4} #{$5}"
          when IRC::RPL_LUSERCHANNELS
            (/^:(\S*)\s(\d*)\s(\S*)\s(\d*)\s:(.*)/) =~ m.message
            print "%Y*** There are #{$4} #{$5}"
          else
            (/^:(\S*)\s(\S*)\s(\S*)\s(.*)/) =~ m.message
            out = $4
            hippy = (/^:(.*)/) =~ out
            out = $1 if !hippy.nil?
            print "%Y*** #{out}"
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
    prompt = "%G>%W"
    if game then ogfileout("gd_enter",1,true) else header end

    while true
      getinp(nil,true) {|l|
        line = l.strip
        puts line
        if game
          if !line.nil? then
            if line.upcase == "HIGH" then
              ogfileout("gd_score",1,true)
              line = nil
            end
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
        if !test.nil? then
          out = $1
          happy = (/^\/(\S*)\s(.*)/) =~ line
          if !happy.nil? then out = $1 end
          case out.to_s.upcase

          when "PAGE"
            page
          when "U"
            displaywho
          when "NICK"
            @irc_client.nick($2)
          when "JOIN"
            @irc_client.join($2)
          when "MOTD"
            @irc_client.motd($2)
          when "VERSION"
            @irc_client.version($2)
          when "TIME"
            @irc_client.time($2)
          when "NAMES"
            @irc_client.names($2)
          when "LIST"
            @irc_client.list($2)
          when "TOPIC"
            @irc_client.topic(channel,$2)
          when "WHOIS"
            @irc_client.whois($2)
          when "ME"
            @irc_client.me(channel,$2)
          when "MSG"
            doit = (/^\/(\S*)\s(\S*)\s(.*)/) =~ line
            @irc_client.privmsg($2,$3) if doit
          when "QUIT"
            @irc_client.quit($2)
            @irc_client.shutdown
            @irc_cleint = nil
            return
          end
        else
          if line =="?" then
            gfileout("chatmnu")
          else
            g_test = (/(\S*)(.*)/) =~ line
            if !g_test.nil? then cmd = $1.upcase else cmd = "" end
            #puts "cmd:#{cmd}"
            #puts "@gd_game:#{@gd_game}"
            #puts "@gd_mode:#{@gd_mode}"
            # if (GD_COMMANDS.index("#{cmd}") != nil or @gd_mode) and @gd_game then
            # @irc_client.privmsg(GD_IRCUSER,line) if !line.nil?
            # else
            @irc_client.privmsg(@irc_channel,line) if !line.nil?
            #	end
          end

        end

        @chatbuff.each {|x|

          print parse_ircc(x)}
          @chatbuff.clear
      }
    end
  end



  def checkuseralias
    if @c_user.alias.nil? then
      @c_user.alias = defaultalias(@c_user.name)
      update_user(@c_user)
      print <<-here
      %RYou have not selected a chat alias!
      %GYou have been assigned the default alias of %Y#{@c_user.alias}
      %GThis can be changed from the user configuration menu [#%Y%%G]
      here
      return false
    end
    return true
  end
end
