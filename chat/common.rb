=begin

= chat/common.rb

       Jonathan Perkin <jonathan@perkin.org.uk> wrote this file
 
  You can freely distribute/modify it (and are encouraged to do so),
  and you are welcome to buy me a beer if we ever meet and you think
  this stuff is worth it.  Improvements and cleanups always welcome.

  $sketch: common.rb,v 1.17 2003/03/03 17:55:45 sketch Exp $

=end

require 'observer'
require 'socket'


module Kernel
  def with_module(*consts, &blk)
    slf = blk.binding.eval('self')
    l = lambda { slf.instance_eval(&blk) }
    consts.reverse.inject(l) {|l, k| lambda { k.class_eval(&l) } }.call
  end
end

module Chat

  # Basic client components
  class Client



    # Include changed/notify_observers methods.
    include Observable

    def initialize(host, port)
    #  @sock = TCPsocket.open(host, port)
  # with_module(IRC,Chat) do
    begin
      @sock = TCPSocket.open(host, port)

    rescue
     puts "-Error: cannot resolve IRC server."
   end
    end

    def send_raw(message)
      if message
        @sock.send("#{message}\r\n", 0)
      end
    end

    def gets_raw

      # Get the next line from the socket.
      reply = @sock.gets

      if reply
        reply.strip!
      end

      return reply

    end

    # Shuts down the receive (how == 0), or send (how == 1), or both
    # (how == 2), parts of this socket.
    def shutdown(how=2)
      @sock.shutdown(how)
    end

    # Broadcast to listeners that the message state has changed.
    def notify_handlers(message)

      # Input status has changed.
      changed

      # Update all listening observers with the new message, and an accurate
      # timestamp for records.
      notify_observers(self, Time.now, message)

    end

  end # class Client

  # Event notification, using the standard Observable class.
  class Event

    # Add an observer.
    def initialize(context)
      context.add_observer(self)
    end

  end # class Event

  # Security checks for passed messages.
  class Security

    # Provide some handy aliases.  Defined by RFC2812 as the following:
    # letter     =  %x41-5A / %x61-7A       ; A-Z / a-z
    # digit      =  %x30-39                 ; 0-9
    # special    =  %x5B-60 / %x7B-7D       ; [, ], \, `, _, ^, {, |, }
    def letter
      
      return "\x41-\x5a\x61-\x7a"
    end
    def digit
      return "\x30-\x39"
    end
    def special
      return Regexp.escape("][\`_^{|}")	
    end

    # Various implementations may want to override this to provide further
    # allowed characters or stricter control.
    def nick
      return "[#{letter}\_]+[#{letter}#{digit}]*"
    end

    # Standard unix username.
    def user
      return "[#{letter}]+[#{letter}#{digit}.]*"
    end

  end # class Security

end # module Chat
