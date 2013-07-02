#-- vim:sw=2:et
	#++
	#
	# :title: Greet Plugin
	#
	# Author:: Raine Virta <rane@kapsi.fi>
	# Copyright:: (C) 2009 Raine Virta
	# License:: GPL v2
	#
	# Description:: Greet people when they join a channel

	class GreetPlugin < Plugin
	  Config.register Config::ArrayValue.new('greet.channels',
	    :desc => _("Greet people on these channels."),
	    :default => ['#test'])
	
	  Config.register Config::ArrayValue.new('greet.messages',
	    :desc => _("By default, greetings are fetched from lang files. You can use this to specify custom messages, use %s to represent a nick."),
	    :default => ["Greetings %s, welcome to the #knownspace channel.  larryniven-l chats are the first Saturday of the month.   If it's not a chat day, chances are no one is actively monitoring the channel, so please be patient if no one responds to you immediately."])
	
	
	
	  def join(m)

	    return if m.source == @bot.myself
	     return unless @bot.config['greet.channels'].include?(m.channel.to_s)

	    greeting = @bot.config['greet.messages'].pick_one
	    who = m.sourcenick

	    if !@registry.has_key?(who) then
	    @bot.say(m.channel, greeting  % m.sourcenick)
	     @registry[who] = Date.today  
	    else
	     if  @registry[who] < Date.today  then  
	       @bot.say(m.channel, greeting  % m.sourcenick)
	     end
	    end 
           @registry[who] = Date.today

	  end
    end

	plugin = GreetPlugin.new