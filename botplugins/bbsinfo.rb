PlugMan.define :bbsinfo do
  author "Mark Firestone"
  version "1.0.0"
  extends({ :main => [:bots] })
  requires []
  extension_points []
  params({ :description =>  "bbsinfo [status | page | who] -> Display BBS information." , :cmd => "bbsinfo"})
	
require "botplugins/support/common.rb"

	def breakline(chell)

	instr = chell.sub(/\s*[\S']+\s+/, "")
	deporter = /^(\S*)\s(.*)/  =~ instr
	cmd =instr
	param = nil
		if deporter then
			cmd = $1
			param = $2
		end
		cmd = "none" if cmd.nil?
		return [cmd,param]
  end

  def display_telnet_users(list,m)
         return ["No telnet users.",dest(m)] if list.len == 0

    out = "#{list.len} Telnet Users:\n" 
    list.each_with_index {|w,i|
      out = out + ("#{w.node}: #{w.name} (#{w.where})\n")}
    return [out + "End of list.",dest(m)]
  end
  
  def telnet_page(who, from, to, message,m)
    return ["Sorry, #{m.sourcenick}, that user is not logged in (via telnet)...",dest(m) ] if who.user(to).nil?
    return ["No blank messages, please",dest(m)] if message.nil? or message.empty?
    add_page(get_uid("SYSTEM"),to,"(IRC from: #{from}): #{message}",false)
    return["Message Sent.",dest(m)]
  end
  
  def do(m,options={})

      cmd,param = breakline(m.params)

    case cmd.downcase
      when 'who'
       display_telnet_users(options[:who],m)

      when 'page'
       happy = /^(.*),(.*)/ =~ param
       if happy then
        telnet_page(options[:who], m.sourcenick, $1, $2,m)
       else
         return["#{m.sourcenick}, I'm really sorry about this, #{m.sourcenick}, but, the page format is !bbsinfo page userid, message",dest(m)]
        end
      else
        out = "I'm afraid I can't do that #{m.sourcenick}!\n" 
        out = out + "Why don't you sit down, take a stress pill, and think things over... " 
        return [out,dest(m)]
      end
     end
    end

