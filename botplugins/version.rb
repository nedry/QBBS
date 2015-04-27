PlugMan.define :version do
  author "Mark Firestone"
  version "1.0.0"
  extends({ :main => [:bots] })
  requires []
  extension_points []
  params({ :description => "Version -> Shows the version of the Bot", :cmd => "version"})
	
	require "botplugins/support/common.rb"

def do(m,options = {})
  return  ["QBBS Bot v.5... With many thanks to Rbot (there are a few bits of it in here)... http://ruby-rbot.org",dest(m)]
end
end
