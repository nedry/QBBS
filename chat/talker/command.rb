=begin

= chat/talker/command.rb

       Jonathan Perkin <jonathan@perkin.org.uk> wrote this file
 
  You can freely distribute/modify it (and are encouraged to do so),
  and you are welcome to buy me a beer if we ever meet and you think
  this stuff is worth it.  Improvements and cleanups always welcome.

  $sketch: command.rb,v 1.7 2003/02/27 23:45:15 sketch Exp $

=end

module Talker

  # Talker commands
  class Command

    def register(nick, pass)

      if pass
        # Only send password for certain types of talkers
        return "#{nick} #{pass}"
      else
        return "#{nick}"
      end

    end

    def join(list)
      return ".join #{list}"
    end

    def quit(quitmsg)
      return ".quit #{quitmsg}"
    end

  end # Class Command

end # module Talker
