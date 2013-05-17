#-- vim:sw=2:et
#++
#
# :title: rbot plugin management

require 'singleton'
require 'consts'

def debug (str)
  puts "-RBOT: Debug ... #{str}"
end
  
class Language  #a hacked up language system.  we're only doing one language...
 def initialize
   scan
 end
 
     def get(key)
      if(@strings.has_key?(key))
        return @strings[key][rand(@strings[key].length)]
      else
        raise "undefined language key"
      end
    end


    def scan
      @strings = Hash.new
      current_key = nil
      IO.foreach(ROOT_PATH  + 'rbot/english.lang') {|l|
        next if l =~ /^$/
        next if l =~ /^\s*#/
        if(l =~ /^(\S+):$/)
          @strings[$1] = Array.new
          current_key = $1
        elsif(l =~ /^\s*(.*)$/)
          @strings[current_key] << $1
        end
      }
    end
  end
  
#module Irc
#class Bot
#    Config.register Config::ArrayValue.new('plugins.blacklist',
 #     :default => [], :wizard => false, :requires_rescan => true,
 #     :desc => "Plugins that should not be loaded")
 #   Config.register Config::ArrayValue.new('plugins.whitelist',
 #     :default => [], :wizard => false, :requires_rescan => true,
 #     :desc => "Only whitelisted plugins will be loaded unless the list is empty")


  module Plugins
    require 'rbot/r_messagemapper'
     require 'open-uri'
    require "rbot/r_httputil"
    
  class Butthole
    def initialize
      @httputil = HttpUtil.new(self)
      @config = Config.manager
      @config.bot_associate(self)
      @lang = Language.new
   end
   
      def say(to,msg)
        $botpassthru.send_me(to,msg)
      end
      
      def lang
         @lang
      end
       
      def who
        $botpassthru.who
      end
      
      def httputil
        @httputil
      end
      
      def config
        @config
      end
      
      def nick
        IRCBOTUSER
      end

      def myself
        IRCBOTUSER
      end
      
     def path(file)
     ROOT_PATH + "rbot/" + file
    end   
  end
    
  class BotModule
    # the associated bot
    attr_reader :bot

    # the plugin registry
    attr_reader :registry

    # the message map handler
    attr_reader :handler

    # Initialise your bot module. Always call super if you override this method,
    # as important variables are set up for you:
    #
    # @bot::
    #   the rbot instance
    # @registry::
    #   the botmodule's registry, which can be used to store permanent data
    #   (see Registry::Accessor for additional documentation)
    #
    # Other instance variables which are defined and should not be overwritten
    # byt the user, but aren't usually accessed directly, are:
    #
    # @manager::
    #   the plugins manager instance
    # @botmodule_triggers::
    #   an Array of words this plugin #register()ed itself for
    # @handler::
    #   the MessageMapper that handles this plugin's maps
    #
   
    def initialize
      @manager = Plugins::manager
      puts "manager.bot: #{@manager}"
      #@bot = @manager
      @priority = nil
        
      @bot = Butthole.new
      @botmodule_triggers = Array.new

      @handler = MessageMapper.new(self)
      #@registry = Registry::Accessor.new(@bot, self.class.to_s.gsub(/^.*::/, ""))

      @manager.add_botmodule(self)
      if self.respond_to?('set_language')
        self.set_language(@bot.lang.language)
      end
    end

    # Changing the value of @priority directly will cause problems,
    # Please use priority=.
    def priority
      @priority ||= 1
    end

    # Returns the symbol :BotModule
    def botmodule_class
      :BotModule
    end

    # Method called to flush the registry, thus ensuring that the botmodule's permanent
    # data is committed to disk
    #
    def flush_registry
      # debug "Flushing #{@registry}"
      @registry.flush
    end

    # Method called to cleanup before the plugin is unloaded. If you overload
    # this method to handle additional cleanup tasks, remember to call super()
    # so that the default cleanup actions are taken care of as well.
    #
    def cleanup
      # debug "Closing #{@registry}"
      @registry.close
    end

    # Handle an Irc::PrivMessage for which this BotModule has a map. The method
    # is called automatically and there is usually no need to call it
    # explicitly.
    #
    def handle(m)
      @handler.handle(m)
    end

    # Signal to other BotModules that an even happened.
    #
    def call_event(ev, *args)
      @bot.plugins.delegate('event_' + ev.to_s.gsub(/[^\w\?!]+/, '_'), *(args.push Hash.new))
    end

    # call-seq: map(template, options)
    #
    # This is the preferred way to register the BotModule so that it
    # responds to appropriately-formed messages on Irc.
    #
    def map(*args)
      do_map(false, *args)
    end

    # call-seq: map!(template, options)
    #
    # This is the same as map but doesn't register the new command
    # as an alternative name for the plugin.
    #
    def map!(*args)
      do_map(true, *args)
    end

    # Auxiliary method called by #map and #map!
    def do_map(silent, *args)
      @handler.map(self, *args)
      # register this map
      map = @handler.last
      name = map.items[0]
      self.register name, :auth => nil, :hidden => silent
      @manager.register_map(self, map)
      unless self.respond_to?('privmsg')
        def self.privmsg(m) #:nodoc:
          handle(m)
        end
      end
    end

    # Sets the default auth for command path _cmd_ to _val_ on channel _chan_:
    # usually _chan_ is either "*" for everywhere, public and private (in which
    # case it can be omitted) or "?" for private communications
    #
    def default_auth(cmd, val, chan="*")
      case cmd
      when "*", ""
        c = nil
      else
        c = cmd
      end
      Auth::defaultbotuser.set_default_permission(propose_default_path(c), val)
    end

    # Gets the default command path which would be given to command _cmd_
    def propose_default_path(cmd)
      [name, cmd].compact.join("::")
    end

    # Return an identifier for this plugin, defaults to a list of the message
    # prefixes handled (used for error messages etc)
    def name
      self.class.to_s.downcase.sub(/^#<module:.*?>::/,"").sub(/(plugin|module)?$/,"")
    end

    # Just calls name
    def to_s
      name
    end

    # Intern the name
    def to_sym
      self.name.to_sym
    end

    # Return a help string for your module. For complex modules, you may wish
    # to break your help into topics, and return a list of available topics if
    # +topic+ is nil. +plugin+ is passed containing the matching prefix for
    # this message - if your plugin handles multiple prefixes, make sure you
    # return the correct help for the prefix requested
    def help(plugin, topic)
      "no help"
    end

    # Register the plugin as a handler for messages prefixed _cmd_.
    #
    # This can be called multiple times for a plugin to handle multiple message
    # prefixes.
    #
    # This command is now superceded by the #map() command, which should be used
    # instead whenever possible.
    #
    def register(cmd, opts={})
      raise ArgumentError, "Second argument must be a hash!" unless opts.kind_of?(Hash)
      who = @manager.who_handles?(cmd)
      if who
        raise "Command #{cmd} is already handled by #{who.botmodule_class} #{who}" if who != self
        return
      end
      if opts.has_key?(:auth)
        @manager.register(self, cmd, opts[:auth])
      else
        @manager.register(self, cmd, propose_default_path(cmd))
      end
      @botmodule_triggers << cmd unless opts.fetch(:hidden, false)
    end

    # Default usage method provided as a utility for simple plugins. The
    # MessageMapper uses 'usage' as its default fallback method.
    #
    def usage(m, params = {})
      if params[:failures].respond_to? :find
        friendly = params[:failures].find do |f|
          f.kind_of? MessageMapper::FriendlyFailure
        end
        if friendly
          m.reply friendly.friendly
          return
        end
      end
      m.reply(_("incorrect usage, ask for help using '%{command}'") % {:command => "#{@bot.nick}: help #{m.plugin}"})
    end

    # Define the priority of the module.  During event delegation, lower
    # priority modules will be called first.  Default priority is 1
    def priority=(prio)
      if @priority != prio
        @priority = prio
        @bot.plugins.mark_priorities_dirty
      end
    end

    # Directory name to be joined to the botclass to access data files. By
    # default this is the plugin name itself, but may be overridden, for
    # example by plugins that share their datafiles or for backwards
    # compatibilty
    def dirname
      name
    end

    # Filename for a datafile built joining the botclass, plugin dirname and
    # actual file name
    def datafile(*fname)
      @bot.path dirname, *fname
    end
  end

  # A CoreBotModule is a BotModule that provides core functionality.
  #
  # This class should not be used by user plugins, as it's reserved for system
  # plugins such as the ones that handle authentication, configuration and basic
  # functionality.
  #
  class CoreBotModule < BotModule
    def botmodule_class
      :CoreBotModule
    end
  end

  # A Plugin is a BotModule that provides additional functionality.
  #
  # A user-defined plugin should subclass this, and then define any of the
  # methods described in the documentation for BotModule to handle interaction
  # with Irc events.
  #
  class Plugin < BotModule
    def botmodule_class
      :Plugin
    end
  end

  # Singleton to manage multiple plugins and delegate messages to them for
  # handling
  class PluginManagerClass
    include Singleton
    attr_reader :bot
    attr_reader :botmodules
    attr_reader :maps

    # This is the list of patterns commonly delegated to plugins.
    # A fast delegation lookup is enabled for them.
    DEFAULT_DELEGATE_PATTERNS = %r{^(?:
      connect|names|nick|
      listen|ctcp_listen|privmsg|unreplied|
      kick|join|part|quit|
      save|cleanup|flush_registry|
      set_.*|event_.*
    )$}x

    def initialize
      @botmodules = {
        :CoreBotModule => [],
        :Plugin => []
      }

      @names_hash = Hash.new
      @commandmappers = Hash.new
      @maps = Hash.new

      # modules will be sorted on first delegate call
      @sorted_modules = nil

      @delegate_list = Hash.new { |h, k|
        h[k] = Array.new
      }

      @core_module_dirs = []
      @plugin_dirs = []

      @failed = Array.new
      @ignored = Array.new

      bot_associate(nil)
    end

    def inspect
      ret = self.to_s[0..-2]
      ret << ' corebotmodules='
      ret << @botmodules[:CoreBotModule].map { |m|
        m.name
      }.inspect
      ret << ' plugins='
      ret << @botmodules[:Plugin].map { |m|
        m.name
      }.inspect
      ret << ">"
    end

    # Reset lists of botmodules
    def reset_botmodule_lists
      @botmodules[:CoreBotModule].clear
      @botmodules[:Plugin].clear
      @names_hash.clear
      @commandmappers.clear
      @maps.clear
      @failures_shown = false
      mark_priorities_dirty
    end

    # Associate with bot _bot_
    def bot_associate(bot)
      reset_botmodule_lists
      @bot = bot
    end

    # Returns the botmodule with the given _name_
    def [](name)
      @names_hash[name.to_sym]
    end

    # Returns +true+ if _cmd_ has already been registered as a command
    def who_handles?(cmd)
      return nil unless @commandmappers.has_key?(cmd.to_sym)
      return @commandmappers[cmd.to_sym][:botmodule]
    end

    # Registers botmodule _botmodule_ with command _cmd_ and command path _auth_path_
    def register(botmodule, cmd, auth_path)
      raise TypeError, "First argument #{botmodule.inspect} is not of class BotModule" unless botmodule.kind_of?(BotModule)
      @commandmappers[cmd.to_sym] = {:botmodule => botmodule, :auth => auth_path}
    end

    # Registers botmodule _botmodule_ with map _map_. This adds the map to the #maps hash
    # which has three keys:
    #
    # botmodule:: the associated botmodule
    # auth:: an array of auth keys checked by the map; the first is the full_auth_path of the map
    # map:: the actual MessageTemplate object
    #
    #
    def register_map(botmodule, map)
      raise TypeError, "First argument #{botmodule.inspect} is not of class BotModule" unless botmodule.kind_of?(BotModule)
      @maps[map.template] = { :botmodule => botmodule, :auth => [map.options[:full_auth_path]], :map => map }
    end

    def add_botmodule(botmodule)
      raise TypeError, "Argument #{botmodule.inspect} is not of class BotModule" unless botmodule.kind_of?(BotModule)
      kl = botmodule.botmodule_class
      if @names_hash.has_key?(botmodule.to_sym)
        case self[botmodule].botmodule_class
        when kl
          raise "#{kl} #{botmodule} already registered!"
        else
          raise "#{self[botmodule].botmodule_class} #{botmodule} already registered, cannot re-register as #{kl}"
        end
      end
      @botmodules[kl] << botmodule
      @names_hash[botmodule.to_sym] = botmodule
      mark_priorities_dirty
    end

    # Returns an array of the loaded plugins
    def core_modules
      @botmodules[:CoreBotModule]
    end

    # Returns an array of the loaded plugins
    def plugins
      @botmodules[:Plugin]
    end

    # Returns a hash of the registered message prefixes and associated
    # plugins
    def commands
      @commandmappers
    end

    # Tells the PluginManager that the next time it delegates an event, it
    # should sort the modules by priority
    def mark_priorities_dirty
      @sorted_modules = nil
    end

    # Makes a string of error _err_ by adding text _str_
    def report_error(str, err)
      ([str, err.inspect] + err.backtrace).join("\n")
    end

    # This method is the one that actually loads a module from the
    # file _fname_
    #
    # _desc_ is a simple description of what we are loading (plugin/botmodule/whatever)
    #
    # It returns the Symbol :loaded on success, and an Exception
    # on failure
    #
    def load_botmodule_file(fname, desc=nil)
      # create a new, anonymous module to "house" the plugin
      # the idea here is to prevent namespace pollution. perhaps there
      # is another way?
      plugin_module = Module.new
      # each plugin uses its own textdomain, we bind it automatically here
      bindtextdomain_to(plugin_module, "rbot-#{File.basename(fname, '.rb')}")

      desc = desc.to_s + " " if desc

   #   begin
        plugin_string = IO.read(fname)
        debug "loading #{desc}#{fname}"
        plugin_module.module_eval(plugin_string, fname)
        return :loaded
   #   rescue Exception => err
        # rescue TimeoutError, StandardError, NameError, LoadError, SyntaxError => err
  #      error report_error("#{desc}#{fname} load failed", err)
 #       bt = err.backtrace.select { |line|
   #       line.match(/^(\(eval\)|#{fname}):\d+/)
   #     }
  #      bt.map! { |el|
  #        el.gsub(/^\(eval\)(:\d+)(:in `.*')?(:.*)?/) { |m|
   #         "#{fname}#{$1}#{$3}"
   #       }
   #     }
  #      msg = err.to_s.gsub(/^\(eval\)(:\d+)(:in `.*')?(:.*)?/) { |m|
   #       "#{fname}#{$1}#{$3}"
    #    }
    #    begin
    #      newerr = err.class.new(msg)
    #    rescue ArgumentError => err_in_err
          # Somebody should hang the ActiveSupport developers by their balls
          # with barbed wire. Their MissingSourceFile extension to LoadError
          # _expects_ a second argument, breaking the usual Exception interface
          # (instead, the smart thing to do would have been to make the second
          # parameter optional and run the code in the from_message method if
          # it was missing).
          # Anyway, we try to cope with this in the simplest possible way. On
          # the upside, this new block can be extended to handle other similar
          # idiotic approaches
       #   if err.class.respond_to? :from_message
      #      newerr = err.class.from_message(msg)
      #    else
     #       raise err_in_err
     #     end
    #    end
    #    newerr.set_backtrace(bt)
    #    return newerr
   #   end
    end
    private :load_botmodule_file

    # add one or more directories to the list of directories to
    # load core modules from
    def add_core_module_dir(*dirlist)
      @core_module_dirs += dirlist
      debug "Core module loading paths: #{@core_module_dirs.join(', ')}"
    end

    # add one or more directories to the list of directories to
    # load plugins from
    def add_plugin_dir(*dirlist)
      @plugin_dirs += dirlist
      debug "Plugin loading paths: #{@plugin_dirs.join(', ')}"
    end

    def clear_botmodule_dirs
      @core_module_dirs.clear
      @plugin_dirs.clear
      debug "Core module and plugin loading paths cleared"
    end

    def scan_botmodules(opts={})
      type = opts[:type]
      processed = Hash.new

      case type
      when :core
        dirs = @core_module_dirs
      when :plugins
        dirs = @plugin_dirs

      #  @bot.config['plugins.blacklist'].each { |p|
       #   pn = p + ".rb"
       #   processed[pn.intern] = :blacklisted
      #  }

   #     whitelist = @bot.config['plugins.whitelist'].map { |p|
    #      p + ".rb"
    #    }
      end
   dirs << ROOT_PATH  + "/plugins"
   
      dirs.each do |dir|
        next unless FileTest.directory?(dir)
        d = Dir.new(dir)
        d.sort.each do |file|
          next unless file =~ /\.rb$/
          next if file =~ /^\./

          case type
          when :plugins
         #   if !whitelist.empty? && !whitelist.include?(file)
          #    @ignored << {:name => file, :dir => dir, :reason => :"not whitelisted" }
          #    next
         #   elsif processed.has_key?(file.intern)
         #     @ignored << {:name => file, :dir => dir, :reason => processed[file.intern]}
         #     next
          #  end

            if(file =~ /^(.+\.rb)\.disabled$/)
              # GB: Do we want to do this? This means that a disabled plugin in a directory
              #     will disable in all subsequent directories. This was probably meant
              #     to be used before plugins.blacklist was implemented, so I think
              #     we don't need this anymore
              processed[$1.intern] = :disabled
              @ignored << {:name => $1, :dir => dir, :reason => processed[$1.intern]}
              next
            end
          end

          did_it = load_botmodule_file("#{dir}/#{file}", "plugin")
          case did_it
          when Symbol
            processed[file.intern] = did_it
          when Exception
            @failed << { :name => file, :dir => dir, :reason => did_it }
          end
        end
      end
    end

    # load plugins from pre-assigned list of directories
    def scan
      @failed.clear
      @ignored.clear
      @delegate_list.clear

    #  scan_botmodules(:type => :core)
      scan_botmodules(:type => :plugins)

      debug "finished loading plugins: #{status(true)}"
      (core_modules + plugins).each { |p|
       p.methods.grep(DEFAULT_DELEGATE_PATTERNS).each { |m|
         @delegate_list[m.intern] << p
       }
      }
      mark_priorities_dirty
    end

    # call the save method for each active plugin
    def save
      delegate 'flush_registry'
      delegate 'save'
    end

    # call the cleanup method for each active plugin
    def cleanup
      delegate 'cleanup'
      reset_botmodule_lists
    end

    # drop all plugins and rescan plugins on disk
    # calls save and cleanup for each plugin before dropping them
    def rescan
      save
      cleanup
      scan
    end

    def status(short=false)
      output = []
      if self.core_length > 0
        if short
          output << n_("%{count} core module loaded", "%{count} core modules loaded",
                    self.core_length) % {:count => self.core_length}
        else
          output <<  n_("%{count} core module: %{list}",
                     "%{count} core modules: %{list}", self.core_length) %
                     { :count => self.core_length,
                       :list => core_modules.collect{ |p| p.name}.sort.join(", ") }
        end
      else
     # output << _("no core botmodules loaded")
      end
      # Active plugins first
      if(self.length > 0)
        if short
          output << n_("(%{count} Program available)", "%{count} Programs available)",
                       self.length) % {:count => self.length}
        else
          output << n_("(%{count} Program): %{list}",
                       "(%{count} Programs): %{list}", self.length) %
                   { :count => self.length,
                     :list => plugins.collect{ |p| p.name}.sort.join(", ") }
        end
      else
        output << "no plugins active"
      end
      # Ignored plugins next
      unless @ignored.empty? or @failures_shown
        if short
          output << n_("%{highlight}%{count} plugin ignored%{highlight}",
                       "%{highlight}%{count} plugins ignored%{highlight}",
                       @ignored.length) %
                    { :count => @ignored.length, :highlight => Underline }
        else
          output << n_("%{highlight}%{count} plugin ignored%{highlight}: use %{bold}%{command}%{bold} to see why",
                       "%{highlight}%{count} plugins ignored%{highlight}: use %{bold}%{command}%{bold} to see why",
                       @ignored.length) %
                    { :count => @ignored.length, :highlight => Underline,
                      :bold => Bold, :command => "help ignored plugins"}
        end
      end
      # Failed plugins next
      unless @failed.empty? or @failures_shown
        if short
          output << n_("%{highlight}%{count} plugin failed to load%{highlight}",
                       "%{highlight}%{count} plugins failed to load%{highlight}",
                       @failed.length) %
                    { :count => @failed.length, :highlight => Reverse }
        else
          output << n_("%{highlight}%{count} plugin failed to load%{highlight}: use %{bold}%{command}%{bold} to see why",
                       "%{highlight}%{count} plugins failed to load%{highlight}: use %{bold}%{command}%{bold} to see why",
                       @failed.length) %
                    { :count => @failed.length, :highlight => Reverse,
                      :bold => Bold, :command => "help failed plugins"}
        end
      end
      output.join '; '
    end

    # return list of help topics (plugin names)
    def helptopics
      rv = status
      @failures_shown = true
      rv
    end

    def length
      plugins.length
    end

    def core_length
      core_modules.length
    end

    # return help for +topic+ (call associated plugin's help method)
    def help(topic="")
      case topic
      when /fail(?:ed)?\s*plugins?.*(trace(?:back)?s?)?/
        # debug "Failures: #{@failed.inspect}"
        return _("No programs failed to load") if @failed.empty?
        return @failed.collect { |p|
          _('%{highlight}%{plugin}%{highlight} in %{dir} failed with error %{exception}: %{reason}') % {
              :highlight => Bold, :plugin => p[:name], :dir => p[:dir],
              :exception => p[:reason].class, :reason => p[:reason],
          } + if $1 && !p[:reason].backtrace.empty?
                _('at %{backtrace}') % {:backtrace => p[:reason].backtrace.join(', ')}
              else
                ''
              end
        }.join("\n")
      when /ignored?\s*plugins?/
        return _('No programs were ignored') if @ignored.empty?

        tmp = Hash.new
        @ignored.each do |p|
          reason = p[:loaded] ? _('overruled by previous') : _(p[:reason].to_s)
          ((tmp[p[:dir]] ||= Hash.new)[reason] ||= Array.new).push(p[:name])
        end

        return tmp.map do |dir, reasons|
          # FIXME get rid of these string concatenations to make gettext easier
          s = reasons.map { |r, list|
            list.map { |_| _.sub(/\.rb$/, '') }.join(', ') + " (#{r})"
          }.join('; ')
          "in #{dir}: #{s}"
        end.join('; ')
      when /^(\S+)\s*(.*)$/
        key = $1
        params = $2

        # Let's see if we can match a plugin by the given name
        (core_modules + plugins).each { |p|
          next unless p.name == key
          begin
            return p.help(key, params)
          rescue Exception => err
            #rescue TimeoutError, StandardError, NameError, SyntaxError => err
            error report_error("#{p.botmodule_class} #{p.name} help() failed:", err)
          end
        }

        # Nope, let's see if it's a command, and ask for help at the corresponding botmodule
        k = key.to_sym
        if commands.has_key?(k)
          p = commands[k][:botmodule]
          begin
            return p.help(key, params)
          rescue Exception => err
            #rescue TimeoutError, StandardError, NameError, SyntaxError => err
            error report_error("#{p.botmodule_class} #{p.name} help() failed:", err)
          end
        end
      end
      return false
    end

    def sort_modules
      @sorted_modules = (core_modules + plugins).sort do |a, b|
        a.priority <=> b.priority
      end || []

      @delegate_list.each_value do |list|
        list.sort! {|a,b| a.priority <=> b.priority}
      end
    end

    # call-seq: delegate</span><span class="method-args">(method, m, opts={})</span>
    # <span class="method-name">delegate</span><span class="method-args">(method, opts={})
    #
    # see if each plugin handles _method_, and if so, call it, passing
    # _m_ as a parameter (if present). BotModules are called in order of
    # priority from lowest to highest.
    #
    # If the passed _m_ is a BasicUserMessage and is marked as #ignored?, it
    # will only be delegated to plugins with negative priority. Conversely, if
    # it's a fake message (see BotModule#fake_message), it will only be
    # delegated to plugins with positive priority.
    #
    # Note that _m_ can also be an exploded Array, but in this case the last
    # element of it cannot be a Hash, or it will be interpreted as the options
    # Hash for delegate itself. The last element can be a subclass of a Hash, though.
    # To be on the safe side, you can add an empty Hash as last parameter for delegate
    # when calling it with an exploded Array:
    #   @bot.plugins.delegate(method, *(args.push Hash.new))
    #
    # Currently supported options are the following:
    # :above ::
    #   if specified, the delegation will only consider plugins with a priority
    #   higher than the specified value
    # :below ::
    #   if specified, the delegation will only consider plugins with a priority
    #   lower than the specified value
    #
    def delegate(method, *args)
      # if the priorities order of the delegate list is dirty,
      # meaning some modules have been added or priorities have been
      # changed, then the delegate list will need to be sorted before
      # delegation.  This should always be true for the first delegation.
      sort_modules unless @sorted_modules

      opts = {}
      opts.merge(args.pop) if args.last.class == Hash

      m = args.first
      if BasicUserMessage === m
        # ignored messages should not be delegated
        # to plugins with positive priority
        opts[:below] ||= 0 if m.ignored?
        # fake messages should not be delegated
        # to plugins with negative priority
        opts[:above] ||= 0 if m.recurse_depth > 0
      end

      above = opts[:above]
      below = opts[:below]

      # debug "Delegating #{method.inspect}"
      ret = Array.new
      if method.match(DEFAULT_DELEGATE_PATTERNS)
        debug "fast-delegating #{method}"
        m = method.to_sym
        debug "no-one to delegate to" unless @delegate_list.has_key?(m)
        return [] unless @delegate_list.has_key?(m)
        @delegate_list[m].each { |p|
          begin
            prio = p.priority
            unless (above and above >= prio) or (below and below <= prio)
              ret.push p.send(method, *args)
            end
          rescue Exception => err
            raise if err.kind_of?(SystemExit)
           # error report_error("#{p.botmodule_class} #{p.name} #{method}() failed:", err)
            raise if err.kind_of?(BDB::Fatal)
          end
        }
      else
        debug "slow-delegating #{method}"
        @sorted_modules.each { |p|
          if(p.respond_to? method)
            begin
              # debug "#{p.botmodule_class} #{p.name} responds"
              prio = p.priority
              unless (above and above >= prio) or (below and below <= prio)
                ret.push p.send(method, *args)
              end
            rescue Exception => err
              raise if err.kind_of?(SystemExit)
              error report_error("#{p.botmodule_class} #{p.name} #{method}() failed:", err)
              raise if err.kind_of?(BDB::Fatal)
            end
          end
        }
      end
      return ret
      # debug "Finished delegating #{method.inspect}"
    end

    # see if we have a plugin that wants to handle this message, if so, pass
    # it to the plugin and return true, otherwise false
    def privmsg(m)
      debug "Delegating privmsg #{m.inspect} with pluginkey #{m.plugin.inspect}"
      return unless m.plugin
      k = m.plugin.to_sym
      if commands.has_key?(k)
        p = commands[k][:botmodule]
        a = commands[k][:auth]
        # We check here for things that don't check themselves
        # (e.g. mapped things)
        debug "Checking auth ..."
   #     if a.nil? || @bot.auth.allow?(a, m.source, m.replyto)
          debug "Checking response ..."
          if p.respond_to?("privmsg")
            begin
              debug "#{p.botmodule_class} #{p.name} responds"
              p.privmsg(m)
            rescue Exception => err
              raise if err.kind_of?(SystemExit)
	      puts "class:#{p.botmodule_class}"
	      puts "pname: #{p.name} privmsg() failed:"
             # error report_error("#{p.botmodule_class} #{p.name} privmsg() failed:", err)
              raise if err.kind_of?(BDB::Fatal)
            end
            debug "Successfully delegated #{m.inspect}"
            return true
          else
            debug "#{p.botmodule_class} #{p.name} is registered, but it doesn't respond to privmsg()"
      #    end
      #  else
     #     debug "#{p.botmodule_class} #{p.name} is registered, but #{m.source} isn't allowed to call #{m.plugin.inspect} on #{m.replyto}"
        end
      else
        debug "Command #{k} isn't handled"
      end
      return false
    end

    # delegate IRC messages, by delegating 'listen' first, and the actual method
    # afterwards. Delegating 'privmsg' also delegates ctcp_listen and message
    # as appropriate.
    def irc_delegate(method, m)
      delegate('listen', m)
      if method.to_sym == :privmsg
        delegate('ctcp_listen', m) if m.ctcp
        delegate('message', m)
        privmsg(m) if m.address? and not m.ignored?
        delegate('unreplied', m) unless m.replied
      else
        delegate(method, m)
      end
    end
  end

  # Returns the only PluginManagerClass instance
def Plugins.manager

    return PluginManagerClass.instance
  end

#end
#end
end
