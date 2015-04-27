PlugMan.define :fortune do
  author "Mark Firestone"
  version "1.0.0"
  extends({ :main => [:bots] })
  requires []
  extension_points []
  params({ :description => "fortune [<module>] => get a (short) fortune, optionally specifying fortune db", :cmd => "fortune"})
	
	require "botplugins/support/common.rb"

def do(m,options = {})
	
	param =""
	happy = /^\!(\S*)\s(.*)/ =~ m.params
	db = $2.downcase if happy
	
	#lets make sure we aren't passing anything dangerous to exec!
	
	happy = /^[^-][\w-]+$/ =~ db 
	db = "" if !happy
	
	
    fortune = nil
    ["/usr/games/fortune", "/usr/bin/fortune", "/usr/local/bin/fortune"].each {|f|
      if FileTest.executable? f
        fortune = f
        break
      end
    }
    return ["fortune binary not found",dest(m)] unless fortune
		db = "" if db.nil?
    ret = safe_exec(fortune, "-n", "255", "-s", db)
    return[ret.gsub(/\t/, "  ").split(/\n/).join(" "),dest(m)]
    return
  end
end

