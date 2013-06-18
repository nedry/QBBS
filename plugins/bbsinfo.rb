#QBBS BBS info plugin... QBBS only.  Will not work on rbot...

class BBSPlugin < Plugin
  def help(plugin, topic="")
  "bbsinfo [status|page|who] => Display BBS information." 
  end

  def display_telnet_users(list,m)
    if list.len == 0
      m.reply("%{highlight}No telnet users.%{highlight}" % {:highlight => Bold })
      return
    end

    m.reply("%{highlight}Telnet Users%{highlight}" % {:highlight => Bold })
    list.each_with_index {|w,i|
      m.reply("#{w.node}: #{w.name} (#{w.where})")
    }
    m.reply("%{highlight}End of list.%{highlight}" % {:highlight => Bold })
  end
  
  def telnet_page(who, from, to, message,m)
    if @bot.who.user(to).nil?
      m.reply("%{highlight}Sorry, #{m.sourcenick}, that user is not logged in (via telnet)...%{highlight}" % {:highlight => Bold })
      return
    end

    if message.nil? or message.empty?
      m.reply("No blank messages, please")
      return
    end

    add_page(get_uid("SYSTEM"),to,"(IRC from: #{from}): #{message}",false)

    m.reply("Message Sent.")
  end
  
  def breakline(instr)
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
  
  def privmsg(m)
    #line = params[:line]
      cmd,param = breakline(m.params)

    case cmd.downcase
      when 'who'
       display_telnet_users(@bot.who,m)

      when 'page'
       happy = /^(.*),(.*)/ =~ param
       if happy then
        telnet_page(@bot.who, m.sourcenick, $1, $2,m)
       else
         m.reply("#{m.sourcenick}, I'm really sorry about this, but, the page format is !bbsinfo page userid, message")
        end
      else
        m.reply "I'm afraid I can't do that #{m.sourcenick}!" 
        m.reply ("Why don't you sit down, take a %{highlight}stress pill%{highlight}, and try the following... " % {:highlight => Bold })
        m.reply(help(m.plugin))
      end
     end
    end
plugin = BBSPlugin.new

plugin.register("bbsinfo")
