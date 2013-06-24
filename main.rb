

class Session
  require 'doors.rb'
  require 'telnet_bbs.rb'

  def leave
    @who.user(@c_user.name).where="Goodbye"
    update_who_t(@c_user.name,"Goodbye")
    if yes("Log off now #{YESNO}", true, false,false) then
      write "%W;"
      ogfileout('bye',1,true)
      print "%WR; NO CARRIER %W;"
      sleep (1)
      hangup
    end
  end

  def youreoutahere
    prompt = "%WR;Disconnect which user number?: %W;"
    which = getnum(prompt,0,@who.len)
    if which > 0 then
      print "%WG;Disconnecting User ##{which} from the system.%W;"
      Thread.kill(@who[which-1].threadn)
    else
      print "%RW; Aborted %W;"
    end
  end


  def page
    to = getinp("%G;User to Page: %W;")
    exists = get_uid(to)
    if exists.nil? then
      print "%WR; That user does not exist. %W;"
      print
      return
    end
    return if to.empty?
    if @who.user(to).nil? and  !who_exists(exists) then
      print "%WR;#{to} is not online... %WG;they will get the message when they log in.%W;"
      print
    end
    message = getinp("%C;Message: %W;")
    return if message.empty?
    add_page(@c_user.number,to,message,false)
    print "%WG;Message Sent.%W;"
  end

  def displaylog(log)
    i = 0
    j = 0
    cont = true
    if !log_empty  then
      cols = %w(Y G C).map {|i| "%"+i +";"}
      hcols = %w(WY WG WC).map {|i| "%"+i +";"}
      headings = %w(Date System Message)
      widths = [18,10,50]
      header = hcols.zip(headings).map {|a,b| a+b}.formatrow(widths) +"%W;"
      underscore = cols.zip(['-'*30]*5).map{|a,b| a+b}.formatrow(widths)

      print header
      print underscore if !@c_user.ansi

      fetch_log(log).each {|x|
        t= Time.parse(x.ent_date.to_s).strftime("%m/%d/%y %I:%M%p")
        temp = cols.zip([t,x.subsys.name,x.message]).map{|a,b| "#{a}#{b}"}.formatrow(widths) #fix for 1.9
        j = j + 1
        if j == (@c_user.length - 2) and @c_user.more then
          cont = moreprompt
          j = 1
          if cont then
            print
            print header
            print underscore if !@c_user.ansi
          end
        end
        break if !cont
        print temp
      }

    else
      print "%WR; System Log Empty %W;"
    end
  end

def picklog
  fetch_subsystems.each{|sub| print "#{sub.subsystem}: #{sub.name}"}
    print
    prompt2 = "Enter Subsystem or #{RET} for all: "
    temp = getnum(prompt2,1,fetch_subsystems.length)
    displaylog(temp)
end

  def commandLoop
    scanforaccess(@c_user)
    while true
      theme = get_user_theme(@c_user) 
      area = fetch_area(@c_area)
      pointer = get_pointer(@c_user,@c_area)
      l_read = new_messages(area.number,pointer.lastread)
      messagemenu(false) if theme.nomainmenu #wbbs mode

      @who.user(@c_user.name).where="Main Menu"
      update_who_t(@c_user.name,"Main Menu")
      o_prompt =  message_prompt(theme.main_prompt,SYSTEMNAME,@c_area,0,l_read,h_msg,area.name,"")
      area = fetch_area(@c_area)
      imp = getinp(o_prompt,false)
      sel = imp.upcase.strip
      parameters = Parse.parse(sel)
      sel.gsub!(/[-\d]/,"")
      ulevel = @c_user.level

      case sel
      when @cmd_hash["bbslist"] ; run_if_ulevel("bbslist") {bbsmenu}
      when @cmd_hash["leave"] ; run_if_ulevel("leave") {leave}
      when @cmd_hash["umaint"] ; run_if_ulevel("umaint") {usermenu}
      when @cmd_hash["kill_log"] ; run_if_ulevel("kill_log") {clearlog}
      when @cmd_hash["amaint"] ; run_if_ulevel("amaint") {areamaintmenu}
      when @cmd_hash["bmaint"] ; run_if_ulevel("bmaint") {bullmaint}
      when @cmd_hash["gmaint"] ; run_if_ulevel("gmaint") {groupmaintmenu}
      when @cmd_hash["tmaint"] ; run_if_ulevel("tmaint") {thememaint}
      when @cmd_hash["dmaint"] ; run_if_ulevel("dmaint") {doormaint}
      when @cmd_hash["omaint"] ; run_if_ulevel("omaint") {telnetmaint}
      when @cmd_hash["smaint"] ; run_if_ulevel("smaint") {screenmaint}
      when @cmd_hash["areachange"] ; run_if_ulevel("areachange") {areachange(parameters)}
      when @cmd_hash["bulletins"] ; run_if_ulevel("bulletins") {bullets(parameters)}
      when @cmd_hash["feedback"] ; run_if_ulevel("feedback") { sendemail(true)}
      when @cmd_hash["teleconference"]
        if IRC_ON then
          run_if_ulevel("teleconference") {teleconference(nil)}
        else
          print "%WR; Teleconference is disabled! %W;\r\n"
        end
      when @cmd_hash["kick"] ; run_if_ulevel("kick") {youreoutahere}
      when @cmd_hash["questionaire"] ; run_if_ulevel("questionaire") {questionaire}
      when @cmd_hash["email"] ; run_if_ulevel("email") {emailmenu}
      when @cmd_hash["doors"] ; run_if_ulevel("doors") {doors(parameters)}
      when @cmd_hash["other"] ; run_if_ulevel("other") {bbs(parameters)}
      when @cmd_hash["email"] ; run_if_ulevel("email") {sendemail(true)}
      when @cmd_hash["post"] ; run_if_ulevel("post") {post}
      when @cmd_hash["usrsetting"] ; run_if_ulevel("usrsetting") {usersettings}
      when @cmd_hash["readmnu"] ; run_if_ulevel("readmnu") {messagemenu(false)}
      when @cmd_hash["zipread"] ; run_if_ulevel("zipread") {messagemenu(true)}
      when @cmd_hash["page"] ; run_if_ulevel("page") {page}
      when @cmd_hash["info"] ; run_if_ulevel("info") {ogfileout("user_information",1,true)}
      when @cmd_hash["version"] ; run_if_ulevel("version") {version}
      when @cmd_hash["who"] ; run_if_ulevel("who") {displaywho}
      when @cmd_hash["log"] ; run_if_ulevel("log") {picklog}
      when @cmd_hash["sysopmnu"] ; run_if_ulevel("sysopmnu") {ogfileout("sysopmnu",1,true)}
      when @cmd_hash["mainmnu"] ; run_if_ulevel("mainmnu") {ogfileout("mainmnu",1,true)}
      end
    end
  end

    def run_if_ulevel(cmd)
      command= get_command(@c_user.theme_key,cmd)

      if  @c_user.level >= command.ulevel
        yield
      else
        print "%WR;You do not have access!%W;"
      end
    end
  end
