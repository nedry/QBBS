

class Session
	require 'doors.rb'
	require 'telnet_bbs.rb'

	def leave
		@who.user(@c_user.name).where="Goodbye"
		update_who_t(@c_user.name,"Goodbye")
		if yes("Log off now #{YESNO}", true, false,false) then
			write "%W%"
			gfileout('bye')
			print "%WR%NO CARRIER%W%"
			sleep (1)
			hangup
		end
	end

	def youreoutahere
		prompt = "%WR%Boot which user number?: %W%"
		which = getnum(prompt,0,@who.len)
		if which > 0 then
			print "%WG%Booting User ##{which} from system.%W%"
                        puts "thread.kill: #{@who[which-1].threadn}"
			Thread.kill(@who[which-1].threadn)
		else
                  print "%RW%Aborted%W%"
		end
	end
	
	
	def page
		to = getinp("%G%User to Page: %W%")
                exists = get_uid(to)
                if exists.nil? then
                  print "%WR%That user does not exist.%W%"
                  print
                  return
                end
		return if to.empty?
		if @who.user(to).nil? and  !who_exists(exists) then
			print "%WR%#{to} is not online... %WG%they will get the message when they log in.%W%"
			print 
		end
		message = getinp("%C%Message: %W%")
		return if message.empty?
                add_page(@c_user.number,to,message,false)
		print "%WG%Message Sent.%W%"
	end
	
 def displaylog
  i = 0
  j = 0
  cont = true
 if !log_empty  then
  cols = %w(Y G C).map {|i| "%"+i +"%"}
  hcols = %w(WY WG WC).map {|i| "%"+i +"%"}
  headings = %w(Date System Message)
  widths = [18,10,50]
  header = hcols.zip(headings).map {|a,b| a+b}.formatrow(widths) +"%W%"
  underscore = cols.zip(['-'*30]*5).map{|a,b| a+b}.formatrow(widths)

			print header
			print underscore if !@c_user.ansi
			fetch_log(0)
  fetch_log(0).each {|x|
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
  print "%WR%System Log Empty%W%"
  end
 end


	def commandLoop
          scanforaccess(@c_user)
             while true
               theme = get_user_theme(@c_user)
               area = fetch_area(@c_area)
               puts "area.name #{area.name}"
               pointer = get_pointer(@c_user,@c_area)
               l_read = new_messages(area.number,pointer.lastread)

              
		@who.user(@c_user.name).where="Main Menu"
		update_who_t(@c_user.name,"Main Menu")
    o_prompt =  message_prompt(theme.main_prompt,SYSTEMNAME,@c_area,0,l_read,h_msg,area.name)
		area = fetch_area(@c_area)
		imp = getinp(o_prompt,false)
			sel = imp.upcase.strip
			parameters = Parse.parse(sel)
			sel.gsub!(/[-\d]/,"")
			ulevel = @c_user.level

			case sel
			when "G" ; leave
			when "UM"; run_if_ulevel {usermenu}
			when "KL"; run_if_ulevel {clearlog}
			when "AM"; run_if_ulevel {areamaintmenu}
			when "BM"; run_if_ulevel {bullmaint}
                        when "GM"; run_if_ulevel {groupmaintmenu}
			when "A"; areachange(parameters)
			when "B"; bullets(parameters)
			when "T";  if IRC_ON then 
				            teleconference(nil) 
					   else
					     print "%WR%Teleconference is disabled!%W%\r\n"
					   end
			when "KU"; youreoutahere if ulevel == 255
			when "Q"; questionaire
			when "ZZ"; new_displaylist
			when "E"; emailmenu
                        when "TM";  thememaint if ulevel == 255
			when "DM"; doormaint if ulevel == 255
			when "TM"; telnetmaint if ulevel ==255
			when "TR" ; print (find_RSTS_account)
			when "GAME" ; doors(parameters)
			when "O"; bbs(parameters)
			when "F"; sendemail(true)
			when "P"; post 
			when "%" ; usersettings
			when "R" ; messagemenu(false)
			when "Z" ; messagemenu(true)
			when "PU" ; page 
			when "S"; ogfileout("user_information",1,true)
			when "V"; version
			when "W"; displaywho
			when "L"; displaylog
			when "X"; ogfileout("sysopmnu",1,true) if ulevel == 255
			when "?"
			        gfileout("mainmnu")
				print "%WG%e%WR%X%WG%tended Sysop Menu%W%" if ulevel == 255
			end
		
		end
	end 

	def run_if_ulevel
		if  @c_user.level == 255
			yield
		else
			print "%WR%You do not have access!%W%"
		end
	end
end
