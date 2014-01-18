=begin

= chat/irc/event.rb

       Jonathan Perkin <jonathan@perkin.org.uk> wrote this file

  You can freely distribute/modify it (and are encouraged to do so),
  and you are welcome to buy me a beer if we ever meet and you think
  this stuff is worth it.  Improvements and cleanups always welcome.

  $sketch: event.rb,v 1.14 2003/02/28 03:11:47 sketch Exp $

=end

module IRC

  # Default container
  class Event < Chat::Event

    # Default handler for ping events.
    class Ping < Event

      # Called by Observable#notify_observers
      def update(client, time, m)

        # Sanity check to see if we should operate on this message.
        if m.is_a? Message::Ping

          # Send ping argument back with a PONG.  Keeps us in the game..

          client.send("PONG #{m.params}")

        end

      end

    end # class Ping

    # Spew out everything we receive
    class Debug < Event

      def update(client, time, m)

        timefmt = "#{time.strftime("%Y-%m-%d %H:%M:%S")}:#{time.tv_usec}"

        print " \n-----\n"
 #       print "  received : #{timefmt}\n"
        print "   message = #{m.message}\n"
        print "      type = #{m.class}\n"

        if m.kind_of? Message::Numeric
          print "serveraddr = #{m.serveraddr}\n"
        end

        if m.kind_of? Message::User
          print "sourcenick = #{m.sourcenick}\n"
          print "sourceuser = #{m.sourceuser}\n"
          print "sourcehost = #{m.sourcehost}\n"
        end

        print "   command = #{m.command}\n"

        if m.kind_of? Message::User or m.is_a? Message::ServerNotice
          print "      dest = #{m.dest}\n"
        end

        print "    params = #{m.params}\n"

      end

    end # class Debug

  end # class Event

end # module IRC
