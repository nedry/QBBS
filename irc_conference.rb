require 'wrap'

module IrcConference
  def parse_ircc(line, ansi, logged_on)
    line = line.to_s.gsub("\t",'')
    if logged_on then
      line = apply_color(IRCCOLORTABLE, line, ansi)
    end
    return line
  end

  def handle_privmsg(m)
    private = false
    sad =(/.*PRIVMSG\s(\S*).*/)  =~ m.message
    if sad then
      private = true if $1.upcase == @irc_alias.upcase
    end
    happy = (/^[\x1](ACTION)(.*)[\x1]/) =~ m.params
    if happy then
      out = "* #{m.sourcenick}#{$2}#{CRLF}%W;"
    else
      if private then
        out = "%WC;PrivM: %B;<#{m.sourcenick}>%C; #{m.params}#{CRLF}%W;"
      else
        out = "%B;<#{m.sourcenick}>%C; #{m.params}#{CRLF}%W;"
      end
    end

    return out
  end

  def handle_notice(m)
    out ="%g;#{m.params}#{CRLF}%W;"
  end
  
  def handle_nick(m)
    (/^:(.*)!(.*)/) =~ m.message
    if $1 == @irc_alias then
      @irc_alias = m.params
      out ="%Y;*** You are now known as #{@irc_alias}#{CRLF}%W;"

    else
      out ="%Y;*** #{$1} is now known as #{m.params}#{CRLF}%W;"
    end
    return out
  end

  def handle_part(m)
    (/^:(.*)!(.*)/) =~ m.message
    out ="%Y;*** #{$1} has left the channel #{m.dest}#{CRLF}%W;"
    return out
  end

  def handle_join(m)
    (/^:(.*)!(.*)/) =~ m.messageW913PB06483
    if $1 == @irc_alias then
      @irc_client.part(@irc_channel)
      @irc_channel = m.params
      out ="%Y;*** You have joined the channel #{@irc_channel}#{CRLF}%W;"
    else
      out ="%Y;*** #{$1} has joined this channel#{CRLF}%W;"
    end
    return out
  end

  def handle_numeric(m)
    case m.command

    when IRC::RPL_NAMREPLY
      (/^:(\S*)\s(\d*)\s(\S*)\s(.*):(.*)/) =~ m.message
      chan = " #{$4}"; users = $5
      happy = (/=(.*)/) =~ chan
      chan = $1 if !happy.nil?
      out = "%Y;*** Users on#{chan}#{users} #{CRLF}%W;"

    when IRC::RPL_WHOISUSER
      (/^:(\S*)\s(\d*)\s(\S*)\s(\S*)\s(\S*)\s(\S*)\s\*\s:(.*)/) =~ m.message
      nick = $4; host = $6; desc = $7;rname= $5
      out = "\r\n\r\n%G;User: %Y;#{nick} %C;is %Y;#{rname}%C;@%Y;#{host} %C;(%Y;#{desc}%C;)\r\n"

    when IRC::RPL_WHOISIDLE
      (/^:(\S*)\s(\d*)\s(\S*)\s(\S*)\s(\S*)\s(\d*)\s(\d*)(.*)/) =~ m.message
      idle_minutes = $5.to_i / 60
      out = "%Y;      #{$4} %C;has been idle for %Y;#{idle_minutes}%C; minute(s).\r\n%W;"

    when IRC::RPL_WHOISCHANNELS
      (/:(.*):(.*)/) =~ m.message
      out ="%C;      on channel(s): %Y;#{$2}\r\n%W;"

    when IRC::RPL_WHOISSERVER
      (/^:(\S*)\s(\d*)\s(\S*)\s(\S*)\s(.*):(.*)/) =~ m.message
      out ="%C;      from server: %Y;#{$5}%C;(%Y;#{$6}%C;)\r\n%W;"
      
    when IRC::RPL_TIME
     (/^:\S*\s\d*\s\S*\s\S*\s:(.*)/) =~ m.message
      out ="%G;Teleconferece time is %Y; #{$1}%W;\r\n\r\n#{IRC_PROMPT}"

    when IRC::RPL_VERSION
      (/^:(\S*)\s(\d*)\s(\S*)\s(.*)/) =~ m.message
      out = "%Y;*** #{$4}#{CRLF}%W;"

    when IRC::RPL_CREATED
      (/^:\S\s(\S*)\s(\S*)\s(.*)/) =~ m.message
      out ="%Y;*** #{$3}#{CRLF}%W;"
      
    when IRC::ERR_NOTEXTTOSEND
      out = "%g;sssshhhhhhh....\r\n#{IRC_PROMPT}"
    when IRC::RPL_LIST

      (/^:(\S*)\s(\d*)\s(\S*)\s(\S*)\s(\d*)\s\:(.*)/) =~ m.message
      chan = " ".ljust(20);users = " ".ljust(5)
      chan = $4.ljust(20) if !$4.empty?
      users = $5.ljust(5) if !$5.empty?
      out = "%Y;#{chan}#{users}#{$6}\r\n"

  when IRC::ERR_NOSUCHNICK,IRC::ERR_NONICKNAMEGIVEN
     out = "%g;Who?\r\n#{IRC_PROMPT}"
  when IRC::RPL_ENDOFWHOIS
     out = "\r\n\r\n#{IRC_PROMPT}"
  when IRC::RPL_LISTSTART
	out =  "\r\n%G;Channel             Users Topic\r\n---------------------------------------------------------------\r\n"
  when IRC::RPL_LISTEND
     out = "%G;\r\nTo switch to any of these channels, type '%C;JOIN <channel>%G;'.\r\n\r\n#{IRC_PROMPT}"
  when 378
     (/^:(.*):(.*)/) =~ m.message
        out ="      %Y;#{$2} #%W;\r\n"
    else
      (/^:(.*):(.*)/) =~ m.message
      #out ="%C;#{$2}\r\n\%W;"
        out ="%g;#{m.command}: #{m.message} #%W;\r\n"
     end
    return out
  end

  def printchat(whole, prompt)
    if @irc_client and @irc_client.isdata then
      out = nil
      m = @irc_client.getline
      params = m.params.strip if !m.nil?
      if m.kind_of? IRC::Message::Private
        out = handle_privmsg(m)
      elsif m.kind_of? IRC::Message::Nick
        out = handle_nick(m)
      elsif m.kind_of? IRC::Message::Part
        out = handle_part(m)
      elsif m.kind_of? IRC::Message::Join
        out = handle_join(m)
      elsif m.kind_of? IRC::Message::Numeric
        out = handle_numeric(m)
      elsif m.kind_of? IRC::Message::ServerNotice
	out = handle_notice(m)
        
      end

      if out then
        w_out = WordWrapper.wrap(out,@c_user.width)
        if (whole == '') then
          write parse_ircc(w_out, @c_user.ansi, @logged_on)
        else
          @chatbuff.push(w_out)
        end
      end
    end
  end
end
