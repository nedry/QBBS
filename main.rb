

class Session
	require 'doors.rb'
	require 'telnet_bbs.rb'
	def userstatus
		usr = @c_user
		ratio = (usr.posted.to_f / usr.logons.to_f) * 100
		print <<-here
		%C          USER STATUS
		__________________________________

		Access Level.................#{usr.level}
		Number of Logons.............#{usr.logons}
		Messages Posted..............#{usr.posted}
		Post/Call Ratio..............#{ratio.to_i}%
		Caller Number................?
		__________________________________
		here
	end

	def leave
		@who.user(@c_user.name).where="Goodbye"
		update_who_t(@c_user.name,"Goodbye")
		if yes("Log off now #{YESNO}", true, false,false) then
			write "%W"
			gfileout('bye')
			print "NO CARRIER"
			sleep (1)
			hangup
		end
	end

	def youreoutahere
		prompt = "Boot which user number?: "
		which = getnum(prompt,0,@who.len)
		if which > 0 then
			print "Booting User ##{which} from system."
			Thread.kill(@who[which-1].threadn)
		else print "Aborted"
		end
	end
	
	
	def page
		to = getinp("%GUser to Page: ")
                exists = get_uid(to)
                if exists.nil? then
                  print "%RThat user does not exist."
                  print
                  return
                end
		return if to.empty?
		if @who.user(to).nil? and  !who_exists(exists) then
			print "%R#{to} is not online... %Gthey will get the message when they log in."
			print 
		end
		message = getinp("%CMessage: ")
		return if message.empty?
                add_page(@c_user.number,to,message,false)
		print "%GMessage Sent."
	end
	
 def displaylog
  i = 0
  j = 0
  cont = true
 if !log_empty  then
  cols = %w(Y G C).map {|i| "%"+i}
  headings = %w(Date System Message)
  widths = [18,10,50]
  header = cols.zip(headings).map {|a,b| a+b}.formatrow(widths)
  underscore = cols.zip(['-'*30]*5).map{|a,b| a+b}.formatrow(widths)

			print header
			print underscore
			fetch_log(0)
  fetch_log(0).each {|x|
   t= Time.parse(x.ent_date.to_s).strftime("%m/%d/%y %I:%M%p")
  temp = cols.zip([t,x.subsys.name,x.message]).map{|a,b| "#{a}#{b}"}.formatrow(widths) #fix for 1.9
  				j = j + 1
				if j == (@c_user.length - 2) and @c_user.more then
					cont = moreprompt
					j = 1
				end
				break if !cont 
  print temp
  }

 else
  print "System Log Empty"
  end
 end


	def commandLoop
             while true
		@who.user(@c_user.name).where="Main Menu"
		update_who_t(@c_user.name,"Main Menu")
		o_prompt = "%G-=%p%W:? for menu%G:=-"
		area = fetch_area(@c_area)
		prompt = o_prompt.gsub("%p","#{area.name}")
		imp = getinp(prompt,false)
			sel = imp.upcase.strip
			parameters = Parse.parse(sel)
			sel.gsub!(/[-\d]/,"")
			ulevel = @c_user.level

			case sel
			when "&" ; print "exists: #{who_t_exists("MARK FIRESTONE")}"; who_delete_t("MARK FIRESTONE")
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
					     print "%RTeleconference is disabled!%W\r\n"
					   end
			when "KU"; youreoutahere if ulevel == 255
			when "Q"; questionaire
			when "ZZ"; new_displaylist
			when "E"; emailmenu
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
			when "S"; userstatus
			when "V"; version
			when "W"; displaywho
			when "L"; displaylog
			when "X"; ogfileout("sysopmnu",1,true) if ulevel == 255
			when "?"
			        gfileout("mainmnu")
				print "%RX - eXtended Sysop Menu" if ulevel == 255
			end
		
		end
	end 

	def run_if_ulevel
		if  @c_user.level == 255
			yield
		else
			print "You do not have access!"
		end
	end
end
