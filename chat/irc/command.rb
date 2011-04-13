=begin

= chat/irc/command.rb

       Jonathan Perkin <jonathan@perkin.org.uk> wrote this file
 
  You can freely distribute/modify it (and are encouraged to do so),
  and you are welcome to buy me a beer if we ever meet and you think
  this stuff is worth it.  Improvements and cleanups always welcome.

  $sketch: command.rb,v 1.7 2003/02/28 00:35:54 sketch Exp $

=end

ACT = "\ca"
module IRC

  # IRC Commands
  class Command

    # 3.2.1 Join message
    #
    #     Command: JOIN
    #  Parameters: ( <channel> *( "," <channel> ) [ <key> *( "," <key> ) ] )
    #                / "0"
    #
    #  The JOIN command is used by a user to request to start listening to
    #  the specific channel.  Servers MUST be able to parse arguments in the
    #  form of a list of target, but SHOULD NOT use lists when sending JOIN
    #  messages to clients.
    #
    #  Once a user has joined a channel, he receives information about
    #  all commands his server receives affecting the channel.  This
    #  includes JOIN, MODE, KICK, PART, QUIT and of course PRIVMSG/NOTICE.
    #  This allows channel members to keep track of the other channel
    #  members, as well as channel modes.
    #
    #  If a JOIN is successful, the user receives a JOIN message as
    #  confirmation and is then sent the channel's topic (using RPL_TOPIC) and
    #  the list of users who are on the channel (using RPL_NAMREPLY), which
    #  MUST include the user joining.
    #
    #  Note that this message accepts a special argument ("0"), which is
    #  a special request to leave all channels the user is currently a member
    #  of.  The server will process this message as if the user had sent
    #  a PART command (See Section 3.2.2) for each channel he is a member
    #  of.
    #
    #  Numeric Replies:
    #
    #    ERR_NEEDMOREPARAMS              ERR_BANNEDFROMCHAN
    #    ERR_INVITEONLYCHAN              ERR_BADCHANNELKEY
    #    ERR_CHANNELISFULL               ERR_BADCHANMASK
    #    ERR_NOSUCHCHANNEL               ERR_TOOMANYCHANNELS
    #    ERR_TOOMANYTARGETS              ERR_UNAVAILRESOURCE
    #    RPL_TOPIC
    #
    #  Examples:
    # 
    #    JOIN #foobar                    ; Command to join channel #foobar.
    #    JOIN &foo fubar                 ; Command to join channel &foo using
    #                                      key "fubar".
    #    JOIN #foo,&bar fubar            ; Command to join channel #foo using
    #                                      key "fubar" and &bar using no key.
    #    JOIN 0                          ; Leave all currently joined
    #                                      channels.
    #    :WiZ!jto@oulu.fi JOIN #foobar   ; JOIN from WiZ on channel #foobar

    # XXX: Add key stuff
    def join(channel)
      return "JOIN #{channel}"
    end

    # 4.1.2 Nick message
    #
    #     Command: NICK
    #  Parameters: <nickname> [ <hopcount> ]
    #
    #  NICK message is used to give user a nickname or change the
    #  previous one.  The <hopcount> parameter is only used by servers
    #  to indicate how far away a nick is from its home server.  A
    #  local connection has a hopcount of 0.  If supplied by a client,
    #  it must be ignored.
    #
    #  Numeric Replies:
    #
    #    ERR_NONICKNAMEGIVEN  ERR_ERRONEUSNICKNAME
    #    ERR_NICKNAMEINUSE    ERR_NICKCOLLISION
    #
    #  Example:
    #
    #    NICK Wiz          ; Introducing new nick "Wiz".
    #    :WiZ NICK Kilroy  ; WiZ changed his nickname to Kilroy.

    def nick(nick)
      return "NICK #{nick}"
    end

    # 4.1.3 User message
    # 
    #     Command: USER
    #  Parameters: <username> <hostname> <servername> <realname>
    # 
    #  The USER message is used at the beginning of connection to specify the
    #  username, hostname, servername and realname of a new user.  It is also
    #  used in communication between servers to indicate new user arriving on
    #  IRC, since only after both USER and NICK have been received from a
    #  client does a user become registered.
    # 
    #  Between servers USER must to be prefixed with client's NICKname.
    # 
    #  Numeric Replies:
    # 
    #    ERR_NEEDMOREPARAMS  ERR_ALREADYREGISTRED
    # 
    #  Examples:
    # 
    #    USER guest tolmoon tolsun :Ronnie Reagan
    #    :testnick USER guest tolmoon tolsun :Ronnie Reagan
     
    def user(nick, localhost, server, realname)
      return "USER #{nick} #{localhost} #{server} :#{realname}"
    end
    
    def motd(server)
     return "MOTD #{server}"
    end
    
    def privmsg(destination,message)
     return "PRIVMSG #{destination} :#{message}"
    end
    
    def me(destination,message)
     return "PRIVMSG #{destination} :#{ACT}ACTION #{message}#{ACT}"
    end
    
    def time(destination)
     return "TIME #{destination}"
    end
    
    def version(destination)
     return "VERSION #{destination}"
    end

   def names(params)
     return "NAMES #{params}"
    end
    
   def list(params)
     return "LIST #{params}"
    end
    
  def topic(channel,params)
     return "TOPIC #{channel} #{params}"
    end
    
 def part(channel)
     return "PART #{channel}"
    end
    
  def whois(nick)
     return "WHOIS #{nick}"
    end
    
  def mode(parameters)
    return "MODE #{parameters}"
   end

def oper(user,password)
   return "OPER #{user} #{password}"
  end
    
    # 4.1.6 Quit
    #
    #     Command: QUIT
    #  Parameters: [<Quit message>]
    #
    #  A client session is ended with a quit message.  The server must close
    #  the connection to a client which sends a QUIT message. If a "Quit
    #  Message" is given, this will be sent instead of the default message,
    #  the nickname.
    #
    #  Numeric Replies:
    #
    #    None.
    #
    #  Examples:
    #
    #    QUIT :Gone to have lunch

    def quit(message)
      return "QUIT :#{message}"
    end

  end # Class Command

end # module IRC
