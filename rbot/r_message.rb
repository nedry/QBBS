#-- vim:sw=2:et
#++
#
# :title: IRC message datastructures

#module Irc
require "consts"

  #class Bot
  #  module Config
   #   Config.register ArrayValue.new('core.address_prefix',
    #    :default => [], :wizard => true,
     #   :desc => "what non nick-matching prefixes should the bot respond to as if addressed (e.g !, so that '!foo' is treated like 'rbot: foo')"
     # )

    #  Config.register BooleanValue.new('core.reply_with_nick',
     #   :default => false, :wizard => true,
      #  :desc => "if true, the bot will prepend the nick to what he has to say when replying (e.g. 'markey: you can't do that!')"
     # )

    #  Config.register StringValue.new('core.nick_postfix',
    #    :default => ':', :wizard => true,
    #    :desc => "when replying with nick put this character after the nick of the user the bot is replying to"
    #  )
   #   Config.register BooleanValue.new('core.private_replies',
    #    :default => false,
     #   :desc => 'Should the bot reply to private instead of the channel?'
     # )
   # end
 # end


  # Define standard IRC attriubtes (not so standard actually,
  # but the closest thing we have ...)
  Bold = "\002"
  Underline = "\037"
  Reverse = "\026"
  Italic = "\011"
  NormalText = "\017"
  AttributeRx = /#{Bold}|#{Underline}|#{Reverse}|#{Italic}|#{NormalText}/

  # Color is prefixed by \003 and followed by optional
  # foreground and background specifications, two-digits-max
  # numbers separated by a comma. One of the two parts
  # must be present.
  Color = "\003"
  ColorRx = /#{Color}\d?\d?(?:,\d\d?)?/

  FormattingRx = /#{AttributeRx}|#{ColorRx}/

  # Standard color codes
  ColorCode = {
    :black      => 1,
    :blue       => 2,
    :navyblue   => 2,
    :navy_blue  => 2,
    :green      => 3,
    :red        => 4,
    :brown      => 5,
    :purple     => 6,
    :olive      => 7,
    :yellow     => 8,
    :limegreen  => 9,
    :lime_green => 9,
    :teal       => 10,
    :aqualight  => 11,
    :aqua_light => 11,
    :royal_blue => 12,
    :hotpink    => 13,
    :hot_pink   => 13,
    :darkgray   => 14,
    :dark_gray  => 14,
    :lightgray  => 15,
    :light_gray => 15,
    :white      => 16
  }

  # Convert a String or Symbol into a color number
  def find_color(data)
    "%02d" % if Integer === data
      data
    else
      f = if String === data
            data.intern
          else
            data
          end
      if ColorCode.key?(f)
        ColorCode[f]
      else
        0
      end
    end
  end

  # Insert the full color code for a given
  # foreground/background combination.
  def color(fg=nil,bg=nil)
    str = Color.dup
    if fg
     str << Irc.find_color(fg)
    end
    if bg
      str << "," << Irc.find_color(bg)
    end
    return str
  end

  # base user message class, all user messages derive from this
  # (a user message is defined as having a source hostmask, a target
  # nick/channel and a message part)
  class BasicUserMessage

    # associated bot
    attr_reader :bot

    # associated server
    attr_reader :server

    # when the message was received
    attr_reader :time

    # User that originated the message
    attr_reader :source

    # User/Channel message was sent to
    attr_reader :target

    # contents of the message (stripped of initial/final format codes)
    attr_accessor :message

    # contents of the message (for logging purposes)
    attr_accessor :logmessage

    # contents of the message (stripped of all formatting)
    attr_accessor :plainmessage

    # has the message been replied to/handled by a plugin?
    attr_accessor :replied
    alias :replied? :replied

    # should the message be ignored?
    attr_accessor :ignored
    alias :ignored? :ignored

    # set this to true if the method that delegates the message is run in a thread
    attr_accessor :in_thread
    alias :in_thread? :in_thread

    def inspect(fields=nil)
     ret = self.__to_s__[0..-2]
     ret << ' bot=' << @irc_bot.__to_s__
    #  ret << ' server=' << server.to_s
      ret << ' time=' << time.to_s
      ret << ' source=' << source.to_s
      ret << ' target=' << target.to_s
      ret << ' message=' << message.inspect
      ret << ' logmessage=' << logmessage.inspect
      ret << ' plainmessage=' << plainmessage.inspect
      ret << fields if fields
      ret << ' (identified)' if identified?
      if address?
        ret << ' (addressed to me'
        ret << ', with prefix' if prefixed?
        ret << ')'
      end
      ret << ' (replied)' if replied?
      ret << ' (ignored)' if ignored?
      ret << ' (in thread)' if in_thread?
      ret << '>'
    end

    # instantiate a new Message
    # bot::      associated bot class
    # server::   Server where the message took place
    # source::   User that sent the message
    # target::   User/Channel is destined for
    # message::  actual message
    def initialize(bot, server, source, target, message)
      @msg_wants_id = false unless defined? @msg_wants_id

      @time = Time.now
      @irc_bot = bot
      @source = source
      @address = false
      @prefixed = false
      @target = target
      @message = message || ""
      @replied = false
      @server = server
      @ignored = false
      @in_thread = false

      @identified = false
      if @msg_wants_id && @server.capabilities[:"identify-msg"]
        if @message =~ /^([-+])(.*)/
          @identified = ($1=="+")
          @message = $2
        else
          warning "Message does not have identification"
        end
      end
      @logmessage = @message.dup
      @plainmessage = BasicUserMessage.strip_formatting(@message)
      @message = BasicUserMessage.strip_initial_formatting(@message)

      if target && target == @irc_bot.myself
        @address = true
      end

    end

    # Access the nick of the source
    #
    def sourcenick
      @source.nick rescue @source.to_s
    end

    # Access the user@host of the source
    #
    def sourceaddress
      "#{@source.user}@#{@source.host}" rescue @source.to_s
    end

    # Access the botuser corresponding to the source, if any
    #
    def botuser
      source.botuser rescue @irc_bot.auth.everyone
    end


    # Was the message from an identified user?
    def identified?
      return @identified
    end

    # returns true if the message was addressed to the bot.
    # This includes any private message to the bot, or any public message
    # which looks like it's addressed to the bot, e.g. "bot: foo", "bot, foo",
    # a kick message when bot was kicked etc.
    def address?
      return @address
    end

    # returns true if the messaged was addressed to the bot via the address
    # prefix. This can be used to tell appart "!do this" from "botname, do this"
    def prefixed?
      return @prefixed
    end

    # strip mIRC colour escapes from a string
    def BasicUserMessage.stripcolour(string)
      return "" unless string
      ret = string.gsub(ColorRx, "")
      #ret.tr!("\x00-\x1f", "")
      ret
    end

    def BasicUserMessage.strip_initial_formatting(string)
      return "" unless string
      ret = string.gsub(/^#{FormattingRx}|#{FormattingRx}$/,"")
    end

    def BasicUserMessage.strip_formatting(string)
      string.gsub(FormattingRx,"")
    end

  end

  # class for handling welcome messages from the server
  class WelcomeMessage < BasicUserMessage
  end

  # class for handling MOTD from the server. Yes, MotdMessage
  # is somewhat redundant, but it fits with the naming scheme
  class MotdMessage < BasicUserMessage
  end

  # class for handling IRC user messages. Includes some utilities for handling
  # the message, for example in plugins.
  # The +message+ member will have any bot addressing "^bot: " removed
  # (address? will return true in this case)
  class UserMessage < BasicUserMessage

    def inspect
      fields = ' plugin=' << plugin.inspect
      fields << ' params=' << params.inspect
      fields << ' channel=' << channel.to_s if channel
      fields << ' (reply to ' << replyto.to_s << ')'
      if self.private?
        fields << ' (private)'
      else
        fields << ' (public)'
      end
      if self.action?
        fields << ' (action)'
      elsif ctcp
        fields << ' (CTCP ' << ctcp << ')'
      end
      super(fields)
    end

    # for plugin messages, the name of the plugin invoked by the message
    attr_reader :plugin

    # for plugin messages, the rest of the message, with the plugin name
    # removed
    attr_reader :params

    # convenience member. Who to reply to (i.e. would be sourcenick for a
    # privately addressed message, or target (the channel) for a publicly
    # addressed message
    attr_reader :replyto

    # channel the message was in, nil for privately addressed messages
    attr_reader :channel

    # for PRIVMSGs, false unless the message was a CTCP command,
    # in which case it evaluates to the CTCP command itself
    # (TIME, PING, VERSION, etc). The CTCP command parameters
    # are then stored in the message.
    attr_reader :ctcp

    # for PRIVMSGs, true if the message was a CTCP ACTION (CTCP stuff
    # will be stripped from the message)
    attr_reader :action

    # instantiate a new UserMessage
    # bot::      associated bot class
    # source::   hostmask of the message source
    # target::   nick/channel message is destined for
    # message::  message part
    def initialize(bot, server, source, target, message)
      super(bot, server, source, target, message)
      @target = target
      @private = false
      @plugin = nil
      @ctcp = false
      @action = false

      if target == @irc_bot.myself
        @private = true
        @address = true
        @channel = nil
        @replyto = source
      else
        @replyto = @target
        @channel = @target
      end
      puts "debug: @replyto #{@replyto}"
    
      # check for option extra addressing prefixes, e.g "|search foo", or
      # "!version" - first match wins
   #   bot.config['core.address_prefix'].each {|mprefix|
    #    if @message.gsub!(/^#{Regexp.escape(mprefix)}\s*/, "")
     #     @address = true
      #    @prefixed = true
       #   break
       # end
    #  }

      # even if they used above prefixes, we allow for silly people who
      # combine all possible types, e.g. "|rbot: hello", or
      # "/msg rbot rbot: hello", etc
    #  if @message.gsub!(/^\s*#{Regexp.escape(bot.nick)}\s*([:;,>]|\s)\s*/i, "")
     #   @address = true
     # end

      if(@message =~ /^\001(\S+)(\s(.+))?\001/)
        @ctcp = $1
	# FIXME need to support quoting of NULL and CR/LF, see
	# http://www.irchelp.org/irchelp/rfc/ctcpspec.html
        @message = $3 || String.new
        @action = @ctcp == 'ACTION'
        debug "Received CTCP command #{@ctcp} with options #{@message} (action? #{@action})"
        @logmessage = @message.dup
        @plainmessage = BasicUserMessage.strip_formatting(@message)
        @message = BasicUserMessage.strip_initial_formatting(@message)
      end

      # free splitting for plugins
      @params = @message.dup
      # Created messges (such as by fake_message) can contain multiple lines
      if @params.gsub!(/\A\s*(\S+)[\s$]*/m, "")
        @plugin = $1.downcase
        @params = nil unless @params.length > 0
      end
    end

    # returns true for private messages, e.g. "/msg bot hello"
    def private?
      return @private
    end

    # returns true if the message was in a channel
    def public?
      return !@private
    end

    def action?
      return @action
    end

    # convenience method to reply to a message, useful in plugins. It's the
    # same as doing:
    # <tt>@irc_bot.say m.replyto, string</tt>
    # So if the message is private, it will reply to the user. If it was
    # in a channel, it will reply in the channel.
    def plainreply(string, options={})
      reply string, {:nick => false}.merge(options)
    end

    # Same as reply, but when replying in public it adds the nick of the user
    # the bot is replying to
    def nickreply(string, options={})
      reply string, {:nick => true}.merge(options)
    end

    # Same as nickreply, but always prepend the target's nick.
    def nickreply!(string, options={})
      reply string, {:nick => true, :forcenick => true}.merge(options)
    end

    # The general way to reply to a command. The following options are available:
    # :nick [false, true, :auto]
    #   state if the nick of the user calling the command should be prepended
    #   :auto uses core.reply_with_nick
    #
    # :forcenick [false, true]
    #   if :nick is true, always prepend the target's nick, even if the nick
    #   already appears in the reply. Defaults to false.
    #
    # :to [:private, :public, :auto]
    #   where should the bot reply?
    #   :private always reply to the nick
    #   :public reply to the channel (if available)
    #   :auto uses core.private_replies
    def reply(string, options={})
       puts "DEBUG: options: #{options}"
       if @target == IRCBOTUSER then
         to = @source
       else
         to = @channel
       end
      @irc_bot.send_me(to, string)
      @replied = true
    end

    # convenience method to reply to a message with an action. It's the
    # same as doing:
    # <tt>@irc_bot.action m.replyto, string</tt>
    # So if the message is private, it will reply to the user. If it was
    # in a channel, it will reply in the channel.
    def act(string, options={})
      @irc_bot.action @replyto, string, options
      @replied = true
    end

    # send a CTCP response, i.e. a private NOTICE to the sender
    # with the same CTCP command and the reply as a parameter
    def ctcp_reply(string, options={})
      @irc_bot.ctcp_notice @source, @ctcp, string, options
    end

    # convenience method to reply "okay" in the current language to the
    # message
    def plainokay
      self.reply @irc_bot.lang.get("okay"), :nick => false
    end

    # Like the above, but append the username
    def nickokay
      str = @irc_bot.lang.get("okay").dup
      if self.public?
        # remove final punctuation
        str.gsub!(/[!,.]$/,"")
        str += ", #{@source}"
      end
      self.reply str, :nick => false
    end

    # the default okay style is the same as the default reply style
    #
    def okay
      @irc_bot.config['core.reply_with_nick'] ? nickokay : plainokay
    end

    # send a NOTICE to the message source
    #
    def notify(msg,opts={})
      @irc_bot.notice(sourcenick, msg, opts)
    end

  end

  # class to manage IRC PRIVMSGs
  class PrivMessage < UserMessage
    def initialize(bot, server, source, target, message, opts={})
      @msg_wants_id = opts[:handle_id]
      super(bot, server, source, target, message)
    end
  end

  # class to manage IRC NOTICEs
  class NoticeMessage < UserMessage
    def initialize(bot, server, source, target, message, opts={})
      @msg_wants_id = opts[:handle_id]
      super(bot, server, source, target, message)
    end
  end

  # class to manage IRC KICKs
  # +address?+ can be used as a shortcut to see if the bot was kicked,
  # basically, +target+ was kicked from +channel+ by +source+ with +message+
  class KickMessage < BasicUserMessage
    # channel user was kicked from
    attr_reader :channel

    def inspect
      fields = ' channel=' << channel.to_s
      super(fields)
    end

    def initialize(bot, server, source, target, channel, message="")
      super(bot, server, source, target, message)
      @channel = channel
    end
  end

  # class to manage IRC INVITEs
  # +address?+ can be used as a shortcut to see if the bot was invited,
  # which should be true except for server bugs
  class InviteMessage < BasicUserMessage
    # channel user was invited to
    attr_reader :channel

    def inspect
      fields = ' channel=' << channel.to_s
      super(fields)
    end

    def initialize(bot, server, source, target, channel, message="")
      super(bot, server, source, target, message)
      @channel = channel
    end
  end

  # class to pass IRC Nick changes in. @message contains the old nickame,
  # @sourcenick contains the new one.
  class NickMessage < BasicUserMessage
    attr_accessor :is_on
    def initialize(bot, server, source, oldnick, newnick)
      super(bot, server, source, oldnick, newnick)
      @address = (source == @irc_bot.myself)
      @is_on = []
    end

    def oldnick
      return @target
    end

    def newnick
      return @message
    end

    def inspect
      fields = ' old=' << oldnick
      fields << ' new=' << newnick
      super(fields)
    end
  end

  # class to manage mode changes
  class ModeChangeMessage < BasicUserMessage
    attr_accessor :modes
    def initialize(bot, server, source, target, message="")
      super(bot, server, source, target, message)
      @address = (source == @irc_bot.myself)
      @modes = []
    end

    def inspect
      fields = ' modes=' << modes.inspect
      super(fields)
    end
  end

  # class to manage WHOIS replies
  class WhoisMessage < BasicUserMessage
    attr_reader :whois
    def initialize(bot, server, source, target, whois)
      super(bot, server, source, target, "")
      @address = (target == @irc_bot.myself)
      @whois = whois
    end

    def inspect
      fields = ' whois=' << whois.inspect
      super(fields)
    end
  end

  # class to manage NAME replies
  class NamesMessage < BasicUserMessage
    attr_accessor :users
    def initialize(bot, server, source, target, message="")
      super(bot, server, source, target, message)
      @users = []
    end

    def inspect
      fields = ' users=' << users.inspect
      super(fields)
    end
  end

  # class to manager Ban list replies
  class BanlistMessage < BasicUserMessage
    # the bans
    attr_accessor :bans

    def initialize(bot, server, source, target, message="")
      super(bot, server, source, target, message)
      @bans = []
    end

    def inspect
      fields = ' bans=' << bans.inspect
      super(fields)
    end
  end

  class QuitMessage < BasicUserMessage
    attr_accessor :was_on
    def initialize(bot, server, source, target, message="")
      super(bot, server, source, target, message)
      @was_on = []
    end
  end

  class TopicMessage < BasicUserMessage
    # channel topic
    attr_reader :topic
    # topic set at (unixtime)
    attr_reader :timestamp
    # topic set on channel
    attr_reader :channel

    # :info if topic info, :set if topic set
    attr_accessor :info_or_set
    def initialize(bot, server, source, channel, topic=ChannelTopic.new)
      super(bot, server, source, channel, topic.text)
      @topic = topic
      @timestamp = topic.set_on
      @channel = channel
      @info_or_set = nil
    end

    def inspect
      fields = ' topic=' << topic
      fields << ' (set on ' << timestamp << ')'
      super(fields)
    end
  end

  # class to manage channel joins
  class JoinMessage < BasicUserMessage
    # channel joined
    attr_reader :channel

    def inspect
      fields = ' channel=' << channel.to_s
      super(fields)
    end

    def initialize(bot, server, source, channel, message="")
      super(bot, server, source, channel, message)
      @channel = channel
      # in this case sourcenick is the nick that could be the bot
      @address = (source == @irc_bot.myself)
    end
  end

  # class to manage channel parts
  # same as a join, but can have a message too
  class PartMessage < JoinMessage
  end

  # class to handle ERR_NOSUCHNICK and ERR_NOSUCHCHANNEL
  class NoSuchTargetMessage < BasicUserMessage
    # the channel or nick that was not found
    attr_reader :target

    def initialize(bot, server, source, target, message='')
      super(bot, server, source, target, message)

      @target = target
    end
  end

  class UnknownMessage < BasicUserMessage
  end
#end
