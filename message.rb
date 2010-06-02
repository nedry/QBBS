require 'tools.rb'
require 'messagestrings.rb'
require 'menu.rb'
require 'doors.rb'

class Session

 def scanforaccess
  for i in 0..(a_total - 1) do
  area = fetch_area(i)
  @c_user.areaaccess = [] if @c_user.areaaccess == nil
   if @c_user.areaaccess[i] == nil then
    @c_user.areaaccess[i] = area.d_access
    update_user(@c_user,get_uid(@c_user.name))
   end
  end
 end

def displaylist
  cont = false
  user = @c_user
  more = 0
  groups = fetch_groups
  prompt = "%WMore (Y,n) or Area #? "
  prompt2 = "Which, or %Y<--^ for all: "
  print 
  print "%GMessage Groups:"
  groups.each_index {|j| print "#{j}: #{groups[j].groupname}"}
  print
  tempint = getnum(prompt2,-1,groups.length - 1)
  print
  grp = nil
  grp = groups[tempint].number if !tempint.nil?
  displayheader

  fetch_area_list(grp).each_with_index {|area,i|
                                  
				  tempstr = (
				  case @c_user.areaaccess[area.number] 
				   when "I"; "Inv"
                                   when "R"; "Read"
                                   when "W"; "Write"
				   when "N"; "None"
				  end)
				  if (user.areaaccess[area.number] != "I") or (user.level == 255) and (!area.delete) then
				   more +=1
				   l_read = new_messages(area.tbl,user.lastread[area.number])
				   print "%W#{area.number.to_s.ljust(5)}  %G#{l_read.to_s.rjust(4)}  %R#{tempstr.ljust(8)}%Y#{area.group.ljust(10)}%B#{area.name}"
				  end
				  if more > 19 then
                                   cont = yes_num(prompt,true,true)
				   more = 0
				      break if !cont or cont.kind_of?(Fixnum)
                                  end
				  
}
return cont				
 end
 
 def displayheader
  print "%W#      %GNew   %RAccess  %YGroup     %BBoard Description"
  print "%W--     %G----  %R------  %Y-----     %B-----------------"
 end


 def areachange(parameters)
  tempint = -1
  scanforaccess
		
  if (parameters[0] > -1) then 
   tempint = parameters[0] 
  else
    tempint = displaylist
    tempint = -1 if !tempint.kind_of?(Fixnum)
  end

  while true
   if tempint == - 1 then
    prompt = CRLF+"%WArea #[#{@c_area}] (1-#{(a_total - 1)}) ? %Y<--^%W to quit:  " 
    happy = getinp(prompt,false).upcase.strip
    tempint = happy.to_i
   end

   case happy
     when "";   break
     when "CR"; crerror; tempint = -1
     when "?"
       tempint = displaylist
       tempint = -1 if !tempint.kind_of?(Fixnum)
    #else 
    end
     if (0..(a_total - 1)).include?(tempint)
      t = @c_user.areaaccess[tempint]
      area = fetch_area(tempint)
      if t !~ /[NI]/ or (@c_user.level == 255) and (!area.delete)
      @c_area = tempint
      print "%GChanging to the #{area.group}: #{area.name} sub-board"+CRLF
      break
     else
      if t == "N" then 
       print "%RYou do not have access" 
      else
       print "%RThat area does not exist."
      end
       break
      tempint = -1
     end # of if
     else tempint = -1
    end #of if in range
   #end #of case
  end # of while true
  mpointer = p_msg
  mpointer = h_msg if mpointer > h_msg
  #puts "area change m_pointer: #{mpointer}"
  return mpointer
 end # of def

def find_current_area(a_list,num)
 result = nil
 a_list.each_with_index {|list,i|
                          if list.number == num then 
			   result = i
			   break
			  end}
 return result
end

def zipscan(start)
 
 zipfix
 scanforaccess
 a_list = fetch_area_list(nil)
 start = find_current_area(a_list,@c_area)
 
 for i in start..(a_total - 1)
  #area = fetch_area(i)

  @c_user.lastread[a_list[i].number] = 0 if @c_user.lastread[a_list[i].number] == nil
  l_read = new_messages(a_list[i].tbl,@c_user.lastread[a_list[i].number])
  t = @c_user.areaaccess[a_list[i].number]
  if l_read > 0 then
   if @c_user.zipread[a_list[i].number] and (t !~ /[NI]/ or @c_user.level == 255) and (!a_list[i].delete) then
    @c_area = a_list[i].number
    print "%GChanging to the #{a_list[i].group}: #{a_list[i].name} sub-board"+CRLF
    mpointer = p_msg
    sleep (0.5)
    mpointer = h_msg if mpointer > h_msg
    return mpointer
   end
  end
  end
  print "No more messages"
  return nil
 end  

	#-----------------Message Section-------------------  
def qwk_kludge_search(msg_array)	#searches the message buffer for kludge lines and returns them

 tz		= nil
 msgid		= nil
 via		= nil
 reply		= nil
 
 
 
 
 msg_array.each_with_index {|x,i|
				if x.slice(0) == 64 then
                                 x.slice!(0)
				 match = (/^(\S*)(.*)/) =~ x
				 #puts "$1:#{$1} $2:#{$2}"
				 if !match.nil? then 
				  case $1
				   when "MSGID:"
				     msgid = $2.strip
				     msg_array[i] = nil
				   when "VIA:"
				    via = $2.strip
				    msg_array[i] = nil
				   when "TZ:"
				    tz = $2.strip
				    msg_array[i] = nil
				   when "REPLY:"
				    reply = $2.strip
				    msg_array[i] = nil

				  end
				 end
			       #else
                               # break
 				end}
			       

  msg_array.compact!	#Delete every line we marked with a nil, cause it had a kludge we caught!

 
  return [msg_array,msgid,via,tz,reply]
 end
 
 def reply(mpointer)
  private = false
  print
  user = @c_user
  area = fetch_area(@c_area)
     
  if user.areaaccess[@c_area] !~ /[RN]/
   abs = absolute_message(area.tbl,mpointer)
   r_message = fetch_msg(area.tbl, abs)
   to = r_message.m_from
   to.strip! if r_message.network #strip for qwk/rep but not for fido.  Why?
   #puts "to: #{to}"
   #puts "r_message.m_from: #{r_message.m_from}"
   while true 
     prompt = "%GPrivate (y,N,x - abort)? "
     reptype = getinp(prompt,false).strip.upcase
     if (r_message.network or r_message.f_network) and reptype == "Y"
       replyemail(mpointer,@c_area)
       return
     else break end
    end

    case reptype
     when "Y"; private = true
     when "X"; return
    end

    title = r_message.subject
	
    print "%GTitle: #{title}"
    title = get_or_cr("%REnter Title (<CR> for old): ", title)
    reply_text = []
    reply_text.push(">--- #{to} wrote ---")
    r_message.msg_text.each(DLIM) {|line| reply_text.push("> #{line.chop!}")}
     if @c_user.fullscreen then
      write "%W"
      msg_file = write_quote_msg(reply_text)
      launch_editor(msg_file)
      suck_in_text(msg_file)
      prompt = "Post message (Y,n)? "
      saveit = yes(prompt, true, false,true)
     else
      saveit = lineedit(1,reply_text)
     end
    if (saveit) then
     x = private ? 0 : @c_area
     savecurmessage(x, to, title, false,true,nil,nil,nil,nil)
     print private ? "Sending Private Mail..." : "%GSaving Message.."
   else 
    print "%RMessage Cancelled."
   end
  end
 end

 def savecurmessage(x, to, title,exported,reply,destnode,destnet,intl,point)
  area = fetch_area(x)
  @lineeditor.msgtext << DLIM
  msg_text = @lineeditor.msgtext.join(DLIM)
  m_from = @c_user.name
  msg_date = Time.now.strftime("%Y-%m-%d %I:%M%p")
  absolute = add_msg(area.tbl,to,m_from,msg_date,title,msg_text,exported,false,reply,destnode,destnet,intl,point,false)
  add_log_entry(5,Time.now,"#{@c_user.name} posted message absolute # #{absolute}")
 end

	def get_or_cr(prompt, crvalue)
		until DONE
			tempstr = getinp(prompt,false).strip
			break if tempstr.upcase != "CR"
			crerror
		end
		emptyv(tempstr, crvalue)
	end

 def write_quote_msg(reply_text) 
  
   num = rand(100000).to_s
   outfile = "msg#{num}"
   path = "#{FULLSCREENDIR}/#{outfile}"
   quotefile = File.new(path, File::CREAT|File::APPEND|File::RDWR, 0666)
   quotefile.puts "#{CRLF}"
   reply_text.each {|line| quotefile.puts "#{line.chop![0..75]}#{CRLF}"} if reply_text != nil
   quotefile.close
   return outfile
 end
 
 def suck_in_text(msg_file)
 begin
 rescue
 print "wow"
 end
 @lineeditor.msgtext = []
 if File.exists?("#{FULLSCREENDIR}/#{msg_file}") 
  IO.foreach("#{FULLSCREENDIR}/#{msg_file}") { |line| @lineeditor.msgtext.push(line.chomp!) }
 end		
 #puts  "rm #{FULLSCREENDIR}/#{msg_file}"
 happy = system("rm #{FULLSCREENDIR}/#{msg_file}")
 return true
end


 def launch_editor(msg_file)
  

  
   launch = nil
   launch = FULLSCREENPROG
   launch.gsub!("%a",FULLSCREENDIR)
   print (CLS)
   print (HOME)
   sleep(1)
   puts "launch: #{launch}"
     puts "msg_file: #{msg_file}"
   puts "fullscreendir: #{FULLSCREENDIR}"
   
   puts "string: #{launch} #{FULLSCREENDIR}/#{msg_file}"
   door_do("#{launch} #{FULLSCREENDIR}/#{msg_file}","")
     print (CLS)
     print (HOME)
 end
 
	def post
		scanforaccess
		done = false
		if @c_user.areaaccess[@c_area] =~ /[RN]/
			print "%RYou do not have write access."
			return
		end

		print
		to = get_or_cr("%CTo (<CR> for All): ", "ALL")
		prompt = "%GTitle: "
		title = getinp(prompt,false).strip
		return if title == ""
		reply_text = ["***No Message to Quote***"]
		if @c_user.fullscreen then
		 write "%W"
		 msg_file = write_quote_msg(nil)
		 launch_editor(msg_file)
		 suck_in_text(msg_file)
		 prompt = "Post message (Y,n)? "
                 saveit = yes(prompt, true, false,true)
                else
                 saveit = lineedit(1,reply_text)
                end
		if saveit then
			savecurmessage(@c_area, to, title,false,false,nil,nil,nil,nil)
			@c_user.posted += 1
			update_user(@c_user,get_uid(@c_user.name))
		end
	end # of def post

 def get_orig_address(msgid)
  orig = nil
  match = (/^(\S*)(\S*)/) =~ msgid.strip
  orig = $1 if !match.nil? 
  return orig
 end
 
 def display_fido_header(mpointer)
   area = fetch_area(@c_area)
  if (h_msg > 0) and (mpointer > 0)  then
   table = area.tbl
   @c_user.lastread = Array.new(2,0) if @c_user.lastread == 0
   @c_user.lastread[@c_area] ||= 0
   u = @c_user	
   abs = absolute_message(table,mpointer)
   fidomessage = fetch_msg(table, abs)
   print "Org:       #{fidomessage.orgnet}/#{fidomessage.orgnode}"
   print "Dest:      #{fidomessage.destnet}/#{fidomessage.destnode}"
   print "Attribute: #{fidomessage.attribute}"
   print "Cost:      #{fidomessage.cost}"
   print "Date Time: #{fidomessage.msg_date}"
   print "To:        #{fidomessage.m_to}"
   print "From:      #{fidomessage.m_from}"
   print "Subject:   #{fidomessage.subject}"
   print "Area:      #{fidomessage.area}" if !fidomessage.area.nil?
   print "Msgid:     #{fidomessage.msgid}" if !fidomessage.msgid.nil?
   print "Path:      #{fidomessage.path}" if !fidomessage.path.nil?
   print "TzUTZ:     #{fidomessage.tzutc}" if !fidomessage.tzutc.nil?
   print "CharSet:   #{fidomessage.charset}" if !fidomessage.charset.nil?
   print "Tosser ID: #{fidomessage.tid}" if !fidomessage.tid.nil?
   print "Proc ID:   #{fidomessage.pid}" if !fidomessage.pid.nil?
   print "Intl:      #{fidomessage.intl}" if !fidomessage.intl.nil?
   print "Topt:      #{fidomessage.topt}" if !fidomessage.topt.nil?
   print "Fmpt:      #{fidomessage.fmpt}" if !fidomessage.fmpt.nil?
   print "Reply:     #{fidomessage.reply}" if !fidomessage.reply.nil?
   print "Origin:    #{fidomessage.origin}" if !fidomessage.origin.nil?
   print
 else
   print "\r\n%YThis message area is empty. Why not %G[P]ost%Y a Message?" if h_msg == 0
   print "\r\n%RYou haven't read any messages yet." if mpointer == 0 and h_msg > 0
  end
 end
 
 def parse_intl(address)
 
  happy =  (/^(\d?):(\d{1,4})\/(.*)/) =~ address
  if happy then
   zone = $1;net = $2;node = $3
   grumpy = (/(\d{1,4})\.(\d{1,4})/) =~ node
   if grumpy then
    node = $1;point = $2
   end
  end
   return [zone,net,node,point]
 end
 
 def non_standard_zone(inzone)
 #puts "inzone #{inzone}"
 inzone = inzone[4..7] if inzone.length == 7 
 num = inzone.to_i(16)
 #puts "num: #{num}"
 minutes_utc = num - 65536 
 if minutes_utc > -720 and minutes_utc < 720 then
  hours_utc = minutes_utc / 60.0
  rem_h = hours_utc.ceil
  remainder = minutes_utc - (hours_utc.ceil * 60)
  t_remainder  = remainder.abs.to_s
  t_remainder << "0" if t_remainder.length < 2 
   return "#{rem_h}:#{t_remainder} UTC"
  else
   return "UNKNOWN"
  end
end

 def displaymessage(mpointer,table,email)

   i = 0
   @c_user.lastread = Array.new(2,0) if @c_user.lastread == 0
   @c_user.lastread[@c_area] ||= 0
   u = @c_user	
   if email then
    abs = mpointer
   else		 
    abs = absolute_message(table,mpointer)
   end
   curmessage = fetch_msg(table, abs)
   puts @c_user.lastread[@c_area].class
   if @c_user.lastread[@c_area] < curmessage.number then
    @c_user.lastread[@c_area] = curmessage.number
    update_user(@c_user,get_uid(@c_user.name))
   end
   
    message = []
    curmessage.msg_text.each_line(DLIM) {|line| message.push(line.chop!)}  #changed from .each for ruby 1.9
    
   if curmessage.network then
    message,q_msgid,q_via,q_tz,q_reply = qwk_kludge_search(message)
   end
   #puts q_via
   write "%W##{mpointer} %G[%C#{curmessage.number}%G] %B#{curmessage.msg_date}"
   if !q_tz.nil? then
    tz = q_tz.upcase
    #puts "tz: #{tz}"
    out = TIME_TABLE[tz]
    #puts out
    out = non_standard_zone(tz) if out.nil?
    write " %W(%G#{out}%W)" 
   end
   write "%G [NETWORK MESSAGE]" if curmessage.network
   write "%G [SMTP]" if curmessage.smtp
   write "%G [FIDONET MESSAGE]" if curmessage.f_network
   write "%Y [EXPORTED]" if curmessage.exported and !curmessage.f_network and !curmessage.network
   write "%B [REPLY]" if curmessage.reply
   print ""
   print "%CTo:    %G#{curmessage.m_to}"
   write "%CFrom:  %G#{curmessage.m_from.strip}"
   if curmessage.f_network then 
    out = "UNKNOWN"
    if curmessage.intl != "" then
     if curmessage.intl.length > 1 then
      o_adr = curmessage.intl.split[1]
      zone,net,node,point = parse_intl(o_adr)
      out = "#{zone}:#{net}/#{node}"
      out << ".#{point}" if !point.nil?
     end
    else out = get_orig_address(curmessage.msgid) end
    write " %G(%C#{out}%G)" 
   end
   if curmessage.network then
    out = BBSID
    out = q_via if !q_via.nil?
    write " %G(%C#{out}%G)"
   end
   print
   print "%CTitle: %G#{curmessage.subject}%Y"
   j =5
   cont = true

  
   message.each {|line|
                  j += 1
		  write line
                  if j == u.length - 2 and u.more then
		   print
		   cont = moreprompt
		   
		   j = 1
		   break if !cont 
		  else
		  
		  print end
		 }
   print
 end #displaymesasge
 
        def h_msg
	 area = fetch_area(@c_area)
	 h_msg = m_total(area.tbl)
	end
	
	def p_msg
	 user = @c_user
	 area = fetch_area(@c_area)
	 p_msg = m_total(area.tbl) - new_messages(area.tbl,user.lastread[@c_area])
        end
	
	def messagemenu(zipread)
		@who.user(@c_user.name).where="Message Menu"
	        update_who_t(@c_user.name,"Reading Messages")
		out = "Read" 
		if zipread then
		 out = "ZIPread" 
		 return if !zipscan(1)
		end
		readmenu(
			:out => out,
			:initval => p_msg,
			:range => 1..h_msg,
			:prompt => '"%M[Area #{@c_area}]%C #{sdir} #{out}[%p] '+
			'(1-#{h_msg}): "'
		) {|sel, mpointer, moved, out|
			#puts "total_msg: #{h_msg}"
			#puts "mpointer: #{mpointer}"
			#puts "h_msg: #{h_msg}"
			mpointer = h_msg if mpointer.nil?
			mpointer = h_msg if mpointer > h_msg
#print "sel.integer: #{sel.integer?}"
#print "sel: #{sel}"
			if !sel.integer?
				parameters = Parse.parse(sel)
				sel.gsub!(/[-\d]/,"")
			end

			if moved
				if (mpointer > 0) and (mpointer <= h_msg) then # range check
				 showmessage(mpointer)    
				end
			
			end
			case sel
			when "E";  email
			when "/";  showmessage(mpointer)
			when "PU"; page
			when "K";  killmessage(mpointer)
			when "Q";  mpointer = true  # passing back true tells the other block to exit
			when "G";  leave
			when "P";  post 
			when "W";  displaywho
			when "R";  replytomessage(mpointer)
			when "FH"; display_fido_header(mpointer)
			when "A";  mpointer = areachange(parameters)
			when "MK"; mass_kill(parameters)
			when "?";  gfileout ("readmnu")
			end
			p_return = [mpointer,h_msg,out] # evaluate so this is the value that is returned

		}
	end 

 def killmessage(mpointer)
  
  if mpointer > 0 then
   area = fetch_area(@c_area)
   abs = absolute_message(area.tbl,mpointer)
   d_msg = fetch_msg(area.tbl, abs)

   if d_msg.locked == true then
    print CRLF + "%RCannot Delete. Message Locked."
    return
   end
  
   if !((@c_user.areaaccess[@c_area] =~ /[CM]/) or 
    (@c_user.level == 255) ) then
    print CANNOTKILLMESSAGESERROR
    return
   end

   if h_msg > 0 
    delete_msg(area.tbl,abs)
    print "%RMessage ##{mpointer} [#{abs}] deleted."
   else 
    print CRLF+"%RNo Messages"
   end
  else 
   print CRLF+"%RYou can't delete message 0, because it doesn't exist!"
  end
 end

 def mass_kill(parameters)
 
  area = fetch_area(@c_area)
  start,stop  = parameters[0..1]
  
  puts "start: #{start}"
  puts "stop: #{stop}"
  puts "h_msg: #{h_msg}"
  
  if (start < 1) or (start > h_msg) or (stop < 1) or (stop > h_msg) then
   print "%ROut of Range dude!"
   return
  end
  
   if !((@c_user.areaaccess[@c_area] =~ /[CM]/) or 
   (@c_user.level == 255) ) then
   print CANNOTKILLMESSAGESERROR
   return
  end
  
  first = absolute_message(area.tbl,start)
  last = absolute_message(area.tbl,stop)
  prompt = "%RDelete absolute messages #{first} to #{last} (Y,n)? "
  delete_msgs(area.tbl,first,last) if yes(prompt, true, false,true) 
 end
 
 def replytomessage(mpointer)
  if mpointer > 0 then 
   reply(mpointer)
  else
    print "%GYou haven't read a message yet."
  end
 end

 def showmessage(mpointer)
	 
  area = fetch_area(@c_area)
  if (h_msg > 0) and (mpointer > 0)  then
   displaymessage(mpointer,area.tbl,false) 
  else
   print "\r\n%YThis message area is empty. Why not %G[P]ost%Y a Message?" if h_msg == 0
   print "\r\n%RYou haven't read any messages yet." if mpointer == 0
  end
 end

	#----------------Area Maintaince Section---------------------------

 def displayarea(number)
  area = fetch_area(number)
  write "\r\n%R#%W#{number} %G #{area.name}"
  write "%R [DELETED]" if area.delete 
  write "%R [LOCKED]" if area.locked
  print ""
  if area.netnum > -1 then
   out = area.netnum
  else
   out = "NONE"
  end
  
  print <<-here
  %CDefault Access:   %G#{area.d_access}
  %CValidated Access: %G#{area.v_access}
  %CQWK/REP Net #     %G#{out}
  %CFidoNet Area:     %G#{area.fido_net}
  %CLast Modified:    %G#{area.modify_date}
  %CTotal Messages:   %G#{m_total(area.tbl)}  
  %CSQL Table:        %G#{area.tbl}
  %CGroup:            %G#{area.group}
 here
 
 end #displayarea

 def areamaintmenu 
  readmenu(
   :initval => 0,
   :range => 0..(a_total - 1),
   :prompt => '"%W#{sdir} Area [%p] (0-#{a_total - 1}): "'
    ) {|sel, apointer, moved|
	displayarea(apointer) if moved
         case sel
	  when "/";  displayarea(apointer) 
	  when "Q";  apointer = true
	  when "A";  apointer = addarea 			
	  when "NN"; changeqwkrep(apointer)
	  when "FN"; changefidoarea(apointer)
	  when "CF"; clearfidoarea(apointer)
	  when "W";  displaywho
	  when "PU"; page
	  when "N";  changeareaname(apointer)
	  when "D";  changedefaultaccess(apointer)
	  when "V";  changevalidatedaccess(apointer)
	  when "K";  deletearea(apointer)
	  when "S";  lockarea(apointer)
	  when "G";  leave
	  when "CG"; changegroup(apointer)
	  when "?";  gfileout ("areamnu")
	 end # of case
	p_return = [apointer,(a_total - 1)]
       }
 end

 def deletearea(apointer)
  if apointer <= 1 
   print "%RYou cannot delete area 0 or 1." 
  return
  end
  
  area = fetch_area(apointer)
  
  if area.delete
   area.delete = false
   print "Area ##{apointer} UNdeleted"
  else 
   area.delete = true
   print "Area ##{apointer} deleted."
  end
   update_area(area)
 end

 def lockarea(apointer)

 area = fetch_area(apointer)

  if area.locked then
   area.locked = false
   print "Area ##{apointer} UNlocked"
  else 
   area.locked = true
   print "Area ##{apointer} locked."
  end
 update_area(area)
 end

 def changevalidatedaccess(apointer)

 area = fetch_area(apointer)

  prompt = "Enter new validated access level for board #{apointer}: "
  tempstr2 = getinp(prompt,false).strip.upcase
  if tempstr2 =~ /[NIWRMC]/
   area.v_access = tempstr2
   print "Board #{apointer} validated access changed to #{tempstr2}"
   update_area(area)
  else
   print "%RInvalid Selection"
  end
 end


 def changegroup(apointer)

  area = fetch_area(apointer)
  groups = fetch_groups
  print 
  print "Select New Group #"
  groups.each_index {|j| print "#{j}: #{groups[j].groupname}"}
  prompt = "Enter new group number for board #{apointer}: "
  tempint = getnum(prompt,0,groups.length - 1)
  area.group = groups[tempint].number
  update_group(area)
  print "Area Updated"
 end
 
 def changedefaultaccess(apointer)

  area = fetch_area(apointer)

  prompt = "Enter new default access level for board #{apointer}: "
  tempstr2 = getinp(prompt,false).strip.upcase
   if tempstr2 =~ /[NIWRMC]/
   area.d_access = tempstr2
   print "Board #{apointer} default access changed to #{tempstr2}"
   update_area(area)
  else 
   print "%RInvalid Selection"
  end
 end

 def addarea

  print ADDAREAWARNING
  while true
   prompt = "Enter new area name: "
   name = getinp(prompt,false) {|n| n.strip != ""}.strip
   if name.length > 40 then 
    print "%RName too long.  40 Character Maximum"
   else break end
  end
  while true
   prompt = "Enter new area table: "
   table = getinp(prompt,false) {|p| p.strip != ""}.strip
   if table.length > 10 then
    print "%RTable name too long.  10 Character Maximum"
   else break end
  end
  if table =~ /[A-Za-z]/ 
   commit = yes("Are you sure (Y,n)?",false,false,true)
   if commit then 
    add_area(name,table,"W","W")
    create_msg_table(table)
    apointer = a_total - 1
   else
    print "%RCancelled."
    apointer = a_total - 1
    return
   end
  else
   print "%RTable names must be alpha characters with no space characters"
   apointer = a_total - 1
  end
 end

 def changeqwkrep(apointer)
 
 area = fetch_area(apointer)

  print QWKREPWARNING
 
  while true
  prompt = "Enter new QWK/REP number (N / no mapping): "
  netnum = getinp(prompt,false) {|n| n.strip != ""}.strip
   if netnum =="N" or netnum == "n"
    area.netnum = -1
    break 
   end
   if netnum.to_i > -1 and netnum.to_i < 10000 then
    area.netnum = netnum.to_i
    break
   end 
  end
  update_area(area)
  print
 end


 def changeareaname(apointer)

 area = fetch_area(apointer)

   while true
   prompt = "Enter new area name: "
   name = getinp(prompt,false) {|n| n.strip != ""}.strip
   if name.length > 40 then 
    print "Name too long.  40 Character Maximum"
   else break end
  end
   area.name = name
   update_area(area)
   print
 end
 
 def changefidoarea(apointer)

 area = fetch_area(apointer)

   while true
   prompt = "Enter new FidoNet Area Mapping: "
   fido_net= getinp(prompt,false) {|n| n.strip != ""}.strip
   if fido_net.length > 40 then 
    print "Area too long.  40 Character Maximum"
   else break end
  end
  area.fido_net = fido_net.upcase
  update_area(area)
 end

def clearfidoarea(apointer)

 area = fetch_area(apointer)
 commit = yes("Clear Fidonet Area Mapping.  Are you sure (Y,n)? ",false,false,true)
 
 if commit then 
  area.fido_net = nil
  update_area(area)
  print 
  print "Cleared Fido Mapping"
 else
  print
  print "Not Cleared."
 end
end
end # class Session

