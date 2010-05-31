=begin

= chat/talker/event.rb

       Jonathan Perkin <jonathan@perkin.org.uk> wrote this file
 
  You can freely distribute/modify it (and are encouraged to do so),
  and you are welcome to buy me a beer if we ever meet and you think
  this stuff is worth it.  Improvements and cleanups always welcome.

  $sketch: event.rb,v 1.4 2003/03/03 18:36:54 sketch Exp $

=end

module Talker

  # Default container
  class Event < Chat::Event

    # Spew out everything we receive
    class Debug < Event

      def update(client, time, m)

        timefmt = "#{time.strftime("%Y-%m-%d %H:%M:%S")}:#{time.tv_usec}"

        print " -----\n"
        print "  received : #{timefmt}\n"
        print "   message = #{m.message}\n"
        print "      type = #{m.type}\n"

        if m.kind_of? Message::User
          print "sourcenick = #{m.sourcenick}\n"
        end

        if m.kind_of? Message::List
          print "      list = #{m.list}\n"
        end

        print "    params = #{m.params}\n"

      end

    end # class Debug

  end # class Event

end # module Talker
