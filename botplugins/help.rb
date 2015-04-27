PlugMan.define :help do
  author "Mark Firestone"
  version "1.0.0"
  extends({ :main => [:bots] })
  requires []
  extension_points []
  params({ :description => "Help -> Provides Help", :cmd => "help"})
	
require "botplugins/support/common.rb"

def do(m,options = {})
	
	instr = m.params.to_s

	happy = /^\!(\S*)\s(.*)/ =~ instr
			if happy then
					param = $2.downcase
					out = "No help available for #{param}.  Type !help for a list"
					PlugMan.extensions(:main, :bots).each do |plugin|
									out = plugin.params[:description] if plugin.params.has_value? (param)
					end
					return [out,nil]
       else
	 list = ""
    total = PlugMan.extensions(:main, :bots).length
	  PlugMan.extensions(:main, :bots).each do |plugin|
		list =   "#{list} #{plugin.params[:cmd]}"
	end
	return ["help: (#{total} Programs): #{list}",dest(m)]
end
end
end

