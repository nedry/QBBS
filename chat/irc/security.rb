=begin

= chat/irc/security.rb

       Jonathan Perkin <jonathan@perkin.org.uk> wrote this file
 
  You can freely distribute/modify it (and are encouraged to do so),
  and you are welcome to buy me a beer if we ever meet and you think
  this stuff is worth it.  Improvements and cleanups always welcome.

  $sketch: security.rb,v 1.16 2003/02/28 02:10:31 sketch Exp $

=end

module IRC

  # Security checks for IRC messages
  class Security < Chat::Security

    # nickname   =  ( letter / special ) *8( letter / digit / special / "-" )
    def nick
      return "[#{letter}#{special}]+[#{letter}#{digit}#{special}]*"
    end

    # user       =  1*( %x01-09 / %x0B-0C / %x0E-1F / %x21-3F / %x41-FF )
    #                 ; any octet except NUL, CR, LF, " " and "@"
    
    # Ruby 2.0.0 didn't like the old regexp because of the encoding changes
    # so I made a new regexp
    
    def user

      return "[A-Za-z0-9_`[{}^|\]\\-]+"
      #return "[\x01-\x09\x0b-\x0c\x0e-\x1f\x21-\x3f\x41-\xff]+"
    end

    # hostname   =  shortname *( "." shortname )
    # shortname  =  ( letter / digit ) *( letter / digit / "-" )
    #               *( letter / digit )
    #                 ; as specified in RFC 1123 [HNAME]
    # XXX: Secure me!
    def host
      return "\\S+"
    end

    # serveraddr = hostname
    def serveraddr
      return host
    end

    # Taken from irc2.10.3p3 (why isn't this in an RFC?):
    #
    # ** prefixes used:
    # **      none    I line with ident
    # **      ^       I line with OTHER type ident
    # **      ~       I line, no ident
    # **      +       i line with ident
    # **      =       i line with OTHER type ident
    # **      -       i line, no ident
    def ident
      return "[\\^\\~\\+\\=\\-]?"
    end

    # Full user specification
    def useraddr
    # print "special #{special}"
      return "#{nick}!#{ident}#{user}@#{host}"
    end

    # channel    =  ( "#" / "+" / ( "!" channelid ) / "&" ) chanstring
    #               [ ":" chanstring ]
    # chanstring =  %x01-07 / %x08-09 / %x0B-0C / %x0E-1F / %x21-2B
    # chanstring =/ %x2D-39 / %x3B-FF
    #                 ; any octet except NUL, BELL, CR, LF, " ", "," and ":"
    # channelid  = 5( %x41-5A / digit )   ; 5( A-Z / 0-9 )
    def channel

      # XXX: RFC2812 is broken, they mean %x01-06 not 07 (else it uses BELL)
      #cs = Regexp.escape("[\x01-\x06\x08-\x09\x0b-\x0c\x0e-\x1f\x21-\x2b\x2d-\x39\x3b-\xff]")
      
      cs = ("[^:^\x00^\x07^\,]")  	#instead of including everything, lets exclude what we don't want.
      
      # XXX: Maybe revisit this sometime, but there are too many quirks for me
      #      to spend ages parsing numerics using these special channels.
      ci = "\![#{letter}#{digit}]"

      # 1.3 Channels
      #   Channels names are strings (beginning with a '&', '#', '+' or '!'
      #   character) of length up to fifty (50) characters.
      return "[\#\+\&]#{cs}{1,50}"

    end

    # Either a servername or a single alphanumeric string
    def ping
      return "[#{letter}#{digit}:.]+"	#added the : character here, some (most) servers seem to send it.
    end

    def numeric
      return "[#{digit}]{3}"
    end

  end

end # module IRC
