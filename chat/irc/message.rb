=begin

= chat/irc/message.rb

       Jonathan Perkin <jonathan@perkin.org.uk> wrote this file

  You can freely distribute/modify it (and are encouraged to do so),
  and you are welcome to buy me a beer if we ever meet and you think
  this stuff is worth it.  Improvements and cleanups always welcome.

  $sketch: message.rb,v 1.54 2003/02/28 03:14:35 sketch Exp $

=end

module IRC

  # Split an IRC message up into components
  class Message

    attr_reader :message     # The entire message, unaltered.
    attr_reader :command     # IRC command.
    attr_reader :params      # Command arguments.

    # Pass arguments back up to inherit common variables.
    # IRC messages consist of the following:
    #
    # <message>  ::= [':' <prefix> <SPACE> ] <command> <params> <crlf>
    # <prefix>   ::= <servername> | <nick> [ '!' <user> ] [ '@' <host> ]
    # <command>  ::= <letter> { <letter> } | <number> <number> <number>
    # <SPACE>    ::= ' ' { ' ' }
    # <params>   ::= <SPACE> [ ':' <trailing> | <middle> <params> ]
    #
    # <middle>   ::= <Any *non-empty* sequence of octets not including
    #                 SPACE or NUL or CR or LF, the first of which may not
    #                 be ':'>
    # <trailing> ::= <Any, possibly *empty*, sequence of octets not
    #                 including NUL or CR or LF>
    #
    # <crlf>     ::= CR LF

    def Message.logerror(message)
     print "\nParse (security) error: #{message}\n"
    end

    def Message.parse(message)

      # Don't attempt to parse nothing, we'll match nothing.
      return if message.nil?

      # Provide secure regular expression matching on the specified argument.
      m = IRC::Security.new
    #print "\nm.channel: #{m.channel}\n"

      # Split message up into separate parts


      case message

        # Server messages
  when (/^(PING)\s(#{m.ping})$/i)
   Ping.new(message, $1, $2)

        when (/^(ERROR)\s+:(.*)$/i)
          Error.new(message, $1, $2)

        when (/^:(#{m.serveraddr})\s+(#{m.numeric})\s+(\S+)\s+(.*)$/)
          Numeric.new(message, $1, $2.to_i, $3)

        when (/^:(#{m.serveraddr})\s+(NOTICE)\s+(\S+)\s+:(.*)$/i)
          ServerNotice.new(message, $1, $2, $3, $4)

        #
        # User messages.
        #

        # 3.1.2 Nick message
        #      Command: NICK
        #   Parameters: <nickname>

  #when (/^:(#{m.useraddr})\s(NICK)\s(#{m.nick})$/i)
  # Nick.new(message, $1, $2, $3)

  when (/^:(.*)\s(NICK)\s(.*)$/i)
   m_type = $1; command = $2; params = $3

   secpass = /(#{m.useraddr})/i  =~ m_type
   secpass2 = /(#{m.nick})/i  =~ params
   if !secpass.nil? then
    Nick.new(message, m_type, command, params)
   else
    logerror(message)
   end

        # 3.1.5 User mode message
        #      Command: MODE
        #   Parameters: <nickname>
        #               *( ( "+" / "-" ) *( "i" / "w" / "o" / "O" / "r" ) )
        when (/^:(#{m.nick})\s(MODE)\s(#{m.nick})\s(.*)$/i)
          UserMode.new(message, $1, $2, $3, $4)

        # 3.1.7 Quit
        #      Command: QUIT
        #   Parameters: [ <Quit Message> ]

        when (/^:(.*)\s+(QUIT)\s+[:]?(.*)$/i)
    m_type = $1; command = $2; params = $3
    secpass = /(#{m.useraddr})/i  =~ m_type
    if !secpass.nil? then
           Quit.new(message, m_type, command, params)
    else
     logerror(message)
    end

        # 3.2.1 Join message
        #      Command: JOIN
        #   Parameters: ( <channel> *( "," <channel> )
        #               [ <key> *( "," <key> ) ] ) / "0"

  when (/^:(.*)\s+(JOIN)\s+:(.*)$/i)
     m_type = $1; command = $2; params = $3
           secpass = /(#{m.useraddr})/i  =~ m_type
     if !secpass.nil? then
            Join.new(message, m_type, command, params)
    else
     logerror(message)
    end

        # 3.2.2 Part message
        #      Command: PART
        #   Parameters: <channel> *( "," <channel> ) [ <Part Message> ]
        when (/^:(#{m.useraddr})\s+(PART)\s+(#{m.channel})[:]?(.*)$/i)
  #when (/^:(#{m.useraddr})\s+(PART)\s+(.*)[:]?(.*)$/i)
          Part.new(message, $1, $2, $3, $4)

        # 3.2.3 Channel mode message
        #      Command: MODE
        #   Parameters: <channel> *( ( "-" / "+" ) *<modes> *<modeparams> )
        when (/^:(#{m.useraddr})\s(MODE)\s(#{m.channel})\s(.*)$/i)
          ChanMode.new(message, $1, $2, $3, $4)

        # 3.2.4 Topic message
        #      Command: TOPIC
        #   Parameters: <channel> [ <topic> ]
        when (/^:(#{m.useraddr})\s+(TOPIC)\s+(#{m.channel})\s+:(.*)$/i)
          Topic.new(message, $1, $2, $3, $4)

        # 3.2.7 Invite message
        #      Command: INVITE
        #   Parameters: <nickname> <channel>
        when (/^:(#{m.useraddr})\s+(INVITE)\s+(#{m.nick})\s+:(#{m.channel})$/i)
          Invite.new(message, $1, $2, $3, $4)

        # 3.2.8 Kick command
        #      Command: KICK
        #   Parameters: <channel> *( "," <channel> ) <user> *( "," <user> )
        #               [<comment>]
        when (/^:(#{m.useraddr})\s+(KICK)\s+(#{m.channel})\s+(#{m.nick}\s+:.*)$/i)
          Kick.new(message, $1, $2, $3, $4)

        when (/^:(#{m.useraddr})\s+(PRIVMSG)\s+(\S+)\s+:(.*)$/i)
          Private.new(message, $1, $2, $3, $4)

        when (/^(NOTICE AUTH)\s+(.*)$/i)
    Notice_auth.new(message, $1, $2)

  when (/^:(#{m.useraddr})\s+(NOTICE)\s+(\S+)\s+:(.*)$/i)
          Notice.new(message, $1, $2, $3, $4)

        when (/^:(#{m.useraddr})\s+(PRIVMSG)\s+(\S+)\s+:\001(.*)\001$/i)
          CTCP.new(message, $1, $2, $3, $4)

        # Not supported yet
        else
   logerror(message)


      end

    end

    # Return an array of ["nick", "user", "host"] from "nick!identuser@host"
    def user_to_params(usermask)
  s = IRC::Security.new

     if usermask =~ /(#{s.nick})!#{s.ident}(#{s.user})@(#{s.host})/
        return ["#{$1}", "#{$2}", "#{$3}"]
      end

    end

    # Single server messages
    class Server < Message
      def initialize(message, command, params)
        @message = message  # The complete, unmodified, raw message.
        @command = command  # The command
        @params  = params   # Command arguments
      end
    end

    class Notice_auth < Server; end

    # Set pingcmd and grab the argument.  Some IRC daemons require sending the
    # argument back with the PONG.
    class Ping < Server; end

    # Undefined as yet, not sure if we can parse these generically to provide
    # useful information.  Need to gather some more examples...
    class Error < Server; end

    # Server IRC numeric.  These are quite varied, so we'll need a big
    # parser.  Then again, we don't need to support *all* of them...
    class Numeric < Message
      attr_reader :serveraddr
      def initialize(message, serveraddr, command, params)
        @message    = message     # The complete, unmodified, raw message.
        @serveraddr = serveraddr  # Server address.
        @command    = command     # The numeric command (3 digit number).
        @params     = params      # Numeric arguments.  Random syntax.
      end
    end # class Numeric

    # Server NOTICE - funny things.
    class ServerNotice < Numeric
      attr_reader :dest
      def initialize(message, serveraddr, command, dest, params)
        super(message, serveraddr, command, params)
        @dest = dest  #To whom/what the message was sent.
      end
    end

    # A user message.
    class User < Message
      attr_reader :useraddr, :dest
      attr_reader :sourcenick, :sourceuser, :sourcehost
      def initialize(message, useraddr, command, dest, params)
        @message  = message   # The complete, unmodified, raw message.
        @useraddr = useraddr  # Users full host
        @command  = command   # Command sent.
        @dest     = dest      # To whom/what the message was sent.
        @params   = params    # Full user arguments.

        # Split up who sent the message into separate components.
        @sourcenick, @sourceuser, @sourcehost = user_to_params(useraddr)
      end
    end # class User

    # Nick change message.
    class Nick < Message
      attr_reader :useraddr
      def initialize(message, useraddr, command, params)
        @message  = message   # The complete, unmodified, raw message.
        @useraddr = useraddr  # Users full host
        @command  = command   # Command sent.
        @params   = params    # Full command arguments.
      end
    end # class Nick

    # Quit message.
    class Quit < Message
      attr_reader :useraddr
      def initialize(message, useraddr, command, params)
        @message  = message   # The complete, unmodified, raw message.
        @useraddr = useraddr  # Users full host
        @command  = command   # Command sent.
        @params   = params    # Full command arguments.
      end
    end # class Quit

    # Join message.
    class Join < Message
      attr_reader :useraddr
      def initialize(message, useraddr, command, params)
        @message  = message   # The complete, unmodified, raw message.
        @useraddr = useraddr  # Users full host
        @command  = command   # Command sent.
        @params   = params    # Full command arguments.
      end
    end # class Join

    # Helpful alias classes for user messages
    class UserMode < User; end
    class Part     < User; end
    class ChanMode < User; end
    class Topic    < User; end
    class Invite   < User; end
    class Kick     < User; end
    class Private  < User; end
    class Notice   < User; end
    class CTCP     < User; end

  end # class Message

end # module IRC
