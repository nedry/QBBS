PlugMan.define :template do
  author "The Doctor"
  version "1.0.0"
  extends({ :main => [:bots] })
  requires []
  extension_points []
  params({ :description => "template", :cmd => "template"})
	
	require "botplugins/support/common.rb"

def do(m,options = {})
  return  ["I'm here",dest(m)]
end
end
