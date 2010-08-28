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
    happy = (/^[\x1](ACTION)(.*)[\x1]/) =~ m.params
    if happy then
      out = "* #{m.sourcenick}#{$2}#{CRLF}%W;"
    else
      if m.sourcenick == GD_IRCUSER
        if m.dest == @irc_alias
          @gd_mode = true if params == "+++"
          @gd_mode = false if params == "---"

          if @gd_game
            out = "%C;#{m.params}#{CRLF}%W;"
          else
            out = "%R;PM:%B;<%G;#{m.sourcenick}%B>%C #{m.params}#{CRLF}%W;"
          end
        else
          @gd_game = true if params == "***GAME START"
          @gd_game = false if params == "***GAME STOP"

          if @gd_game
            if m.params[0..2] != "-+-"
              out = "%C#{m.params}#{CRLF}%W"
            else
              out = nil
            end
          else
            out = "%B;<#{m.sourcenick}>%C; #{m.params}#{CRLF}%W;"
          end
        end
      end
    end
    return out
  end

  def handle_nick(m)
    (/^:(.*)!(.*)/) =~ m.message
    if $1 == @irc_alias then
      @irc_alias = m.params
      out ="%Y*** You are now known as #{@irc_alias}#{CRLF}%W"

    else
      out ="%Y*** #{$1} is now known as #{m.params}#{CRLF}%W"
    end
    return out
  end

  def handle_part(m)
    (/^:(.*)!(.*)/) =~ m.message
    out ="%Y*** #{$1} has left the channel #{m.dest}#{CRLF}%W"
    return out
  end

  def handle_join(m)
    (/^:(.*)!(.*)/) =~ m.message
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
      out = "%Y;*** Users on#{chan}#{users} #{CRLF}%W"

    when IRC::RPL_WHOISUSER
      (/^:(\S*)\s(\d*)\s(\S*)\s(\S*)\s(\S*)\s(\S*)\s\*\s:(.*)/) =~ m.message
      nick = $4; host = $6; desc = $7;rname= $5
      out = "%Y;*** #{nick} is #{rname}@#{host} (#{desc})#{CRLF}%W"

    when IRC::RPL_WHOISIDLE
      (/^:(\S*)\s(\d*)\s(\S*)\s(\S*)\s(\S*)\s(\d*)\s(\d*)(.*)/) =~ m.message
      idle_minutes = $5.to_i / 60
      out = "%Y;*** #{$4} has been idle for #{idle_minutes} minute(s).#{CRLF}%W"

    when IRC::RPL_WHOISCHANNELS
      (/^:(.*):(.*)/) =~ m.message
      out ="%Y;*** on channels: #{$2}#{CRLF}%W"

    when IRC::RPL_WHOISSERVER
      (/^:(\S*)\s(\d*)\s(\S*)\s(\S*)\s(.*):(.*)/) =~ m.message
      out ="%Y*** on irc via server #{$5}(#{$6})#{CRLF}%W"

    when IRC::RPL_VERSION
      (/^:(\S*)\s(\d*)\s(\S*)\s(.*)/) =~ m.message
      out = "%Y;*** #{$4}#{CRLF}%W"

    when IRC::RPL_CREATED
      (/^:\S\s(\S*)\s(\S*)\s(.*)/) =~ m.message
      puts "rpl_created"
      out ="%Y;*** #{$3}#{CRLF}%W"

    when IRC::RPL_LIST
      (/^:(\S*)\s(\d*)\s(\S*)\s(\S*)\s(\d*)/) =~ m.message
      out = "%Y;*** There are #{$5} user(s) on channel #{$4}#{CRLF}%W"

    else
      (/^:(.*):(.*)/) =~ m.message
      #(/^:\S\s(\S*)\s(\S*)\s(.*)/) =~ m.message
      out ="%Y;*** #{$2}#{CRLF}%W"
    end

    return out
  end

  def printchat(whole, prompt)
    if @irc_client and @irc_client.isdata then
      out = nil
      m = @irc_client.getline
      params = m.params.strip
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
        out ="#{m.params}#{CRLF}%W;"
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
