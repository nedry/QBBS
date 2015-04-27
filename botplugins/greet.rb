PlugMan.define :greet do
  author "Giuseppe Bilotta"
  version "1.0.0"
  extends({ :main => [:bots] })
  requires []
  extension_points []
  params({ :description => "greet -> Greets Users when entering the channel.  Has no interface.", :join => true})

require "botplugins/support/common.rb"


def do(m,options={})
	   load_registry("greet")
	   greetings= ["Greetings %s, welcome to the #knownspace channel.  larryniven-l chats are the first Saturday of the month.   If it's not a chat day, chances are no one is actively monitoring the channel, so please be patient if no one responds to you immediately."]
		 channels = ["#main"]
		 
		  (/^:(.*)!(.*)/) =~ m.message
			joined = $1

	    return if joined == IRCBOTUSER
			return unless channels.include?(m.params.to_s)

	    greeting = greetings[rand(greetings.length)]


	    if !@registry.has_key?(joined) then
			@registry[joined] = Date.today  
			 save_registry("greet")
			 return [greeting  % joined,m.params]
			 
	    else
	     if  @registry[joined] < Date.today  then  
				 save_registry("greet")
				 return [greeting  % joined,m.params]
	     end
	    end 
           @registry[joined] = Date.today
					 save_registry("greet")
					 return [nil,nil]
	  end
    end
