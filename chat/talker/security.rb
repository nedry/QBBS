=begin

= chat/talker/security.rb

       Jonathan Perkin <jonathan@perkin.org.uk> wrote this file
 
  You can freely distribute/modify it (and are encouraged to do so),
  and you are welcome to buy me a beer if we ever meet and you think
  this stuff is worth it.  Improvements and cleanups always welcome.

  $sketch: security.rb,v 1.3 2003/02/28 00:36:02 sketch Exp $

=end

module Talker

  # Security checks for talker messages.
  class Security < Chat::Security

    # Sensible default
    def nick
      return "[#{letter}#{digit}]+"
    end

    def list
      return nick
    end

  end

end # module IRC
