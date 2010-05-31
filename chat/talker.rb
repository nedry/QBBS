=begin

= chat/talker.rb

       Jonathan Perkin <jonathan@perkin.org.uk> wrote this file
 
  You can freely distribute/modify it (and are encouraged to do so),
  and you are welcome to buy me a beer if we ever meet and you think
  this stuff is worth it.  Improvements and cleanups always welcome.

  $sketch: talker.rb,v 1.12 2003/02/28 00:07:17 sketch Exp $

=end

require 'chat/common'

require 'chat/talker/command'
require 'chat/talker/event'
require 'chat/talker/message'
require 'chat/talker/security'

module Talker

  class Client < Chat::Client

    def initialize(host="localhost", port=5000)
      super
      @talkercmd = Talker::Command.new
    end

    def login(nick, pass=nil)
      send_raw(@talkercmd.register(nick, pass))
    end

    def getline

      # Get next line from server.
      message = Talker::Message.parse(gets_raw)

      if (message)

        # Pass message off to handlers.
        notify_handlers(message)

        # Even though an observer may have handled this event, still pass the
        # message back to the calling client as it might want to do something
        # with it anyway.
        return message

      end

    end

    def join(list)
      send_raw(@talkercmd.join(list))
    end

    def quit(message)
      send_raw(@talkercmd.quit(message))
    end

  end # class Client

end # module Talker
