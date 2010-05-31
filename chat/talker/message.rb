=begin

= chat/talker/message.rb

       Jonathan Perkin <jonathan@perkin.org.uk> wrote this file
 
  You can freely distribute/modify it (and are encouraged to do so),
  and you are welcome to buy me a beer if we ever meet and you think
  this stuff is worth it.  Improvements and cleanups always welcome.

  $sketch: message.rb,v 1.25 2003/03/04 14:55:56 sketch Exp $

=end

module Talker

  # Split a Talker message up into components
  class Message

    attr_reader :message     # The entire message, unaltered.
    attr_reader :params      # The message, minus source/destination.

    # Talker messages fall under these categories:
    #
    #         Server message = +++         <text>
    #          Shout message =     <nick> !<text>
    #          Group message =     <nick> :<text>
    #   Emoted Group message =     <nick>  <text>
    #           List message =     <nick> %<text> {<listname>}
    #    Emoted List message = %   <nick>  <text> {<listname>}
    #        Whisper message =     <nick> ><text>
    # Emoted whisper message = >   <nick>  <text>

    def Message.parse(message)

      # Don't attempt to parse nothing, we'll match nothing.
      return if message.nil?

      # Remove ANSI colours.
      message.gsub!(/\e[^m]+m/, '')

      # Provide secure regular expression matching on the specified argument.
      m = Talker::Security.new

      # Split message up into separate parts
      case message

        # Server message
        when (/^\+\+\+\s*(.*)$/)
          Server.new(message, $1)

        # Group message
        when (/^(#{m.nick})\s+:(.*)$/)
          Group.new(message, $1, $2)

        # Whisper message
        when (/^(#{m.nick})\s+>(.*)$/)
          Whisper.new(message, $1, $2)

        # Emoted whisper message
        when (/^>\s+(#{m.nick})\s+(.*)$/)
          Whisper.new(message, $1, $2)

        # List message
        when (/^(#{m.nick})\s+%(.*)\s{(#{m.list})}$/)
          List.new(message, $1, $2, $3)

        # Emoted list message
        when (/^%\s+(#{m.nick})\s+(.*)\s{(#{m.list})}$/)
          List.new(message, $1, $2, $3)

        # Shout message
        when (/^(#{m.nick})\s+!(.*)$/)
          Shout.new(message, $1, $2)

        # Emoted public message
        when (/^(#{m.nick})\s*(.*)$/)
          Group.new(message, $1, $2)

        # Shouldn't ever get this, but anyway...
        else
        #  raise NotImplementedError, "#{message}"
          
      end

    end

    # Server message
    class Server < Message
      def initialize(message, params)
        @message = message  # The complete, unmodified, raw message.
        @params  = params   # The message itself.
      end
    end

    # Generic user message
    class User < Message
      attr_reader :sourcenick
      def initialize(message, sourcenick, params)
        @message    = message     # The complete, unmodified, raw message.
        @sourcenick = sourcenick  # Who sent the message.
        @params     = params      # The message itself.
      end
    end

    # List message
    class List < User
      attr_reader :list
      def initialize(message, sourcenick, params, list)
        super(message, sourcenick, params)
        @list = list  # List the message was sent to.
      end
    end

    # Helpful alias classes for user messages
    class Group   < User; end
    class Whisper < User; end
    class Shout   < User; end

  end # class Message

end # module Talker
