class Session

 def scanformail
  i = 0
  ptr_check
  u = @c_user
  area = fetch_area(0)
  print; write "Scanning for New Email..."

     #puts "lastread: #{u.lastread[0]}"
  hash = email_lookup_table(area.tbl,u.name)
     #puts "hash: #{hash}"
  total =  e_total(area.tbl,u.name)
  #puts "total: #{total}"
  pointer = find_epointer(hash,u.lastread[0],area.tbl,u.name) 
  if pointer != nil then  
   #puts "pointer: #{pointer}"
   if total > pointer then	
    print "%Gfound!"
    return true
   end
  end
   #puts "pointer: #{pointer}"
   print "none."
  return false
 end

 def ptr_check
   area = fetch_area(0)
   @c_user.lastread ||= [] 
   @c_user.lastread[0] ||= 0
   total = e_total(area.tbl,@c_user.name) 
   update_user(@c_user,get_uid(@c_user.name))
 end
 
 def readitnow
  reademail(true) if yes(CRLF+"Read it now (Y,n)? ", true, false,true)
 end

 def emailmenu
 	@who.user(@c_user.name).where="Email Menu"
	update_who_t(@c_user.name,"Email Menu")
 	out = "Read" 
 	sdir="+"
 	area = fetch_area(0)
   ptr_check
   u = @c_user
   hash = email_lookup_table(area.tbl,u.name)
   #puts "initial hash:#{hash}"
   #puts 
   p_area = @c_area
   @c_area = 0
   epointer = find_epointer(hash,u.lastread[0],area.tbl,u.name)
   #puts "initial epointer: #{epointer}"
   epointer = 1 if epointer == nil 




    done = false
 
 while true
   o_prompt = "%M[Email]%C #{sdir} Read[#{epointer}] (1-#{e_total(area.tbl,u.name)}): "
   inp = getinp(o_prompt,false) 
      
 			happy = inp.upcase.strip 
 			if !happy.integer? 
 				#happy.gsub!(/[-\d]/,"")

 			end

 			case happy
 			
 			when ""; if sdir == "+" then epointer = nextmail(epointer) else epointer = lastmail(epointer) end
 			when "+"; sdir="+"; epointer = nextmail(epointer)
 			when "-"; sdir="-"; epointer = lastmail(epointer)
 			when "G"; leave
 			when "R"; replyemail(epointer,0)
 			when "?"; write "%W"; gfileout ("emailmnu")
 			when "/"; displaymessage(hash[epointer - 1],area.tbl,true)
 			when "K"; deletemessage(epointer-1)
 			when "N"; gfileout ("emailsnd");sendemail(false)
 			when "Q"; break # exit input loop
 			when /\d+/; epointer = jumpemail(happy.to_i,epointer,e_total(area.tbl,u.name)+1)
 			else; print "Out of Range."
 			end #of case 
 			done
 	end
 		@c_area = p_area

 end
 def jumpemail(inp,epointer,max)
   ptr_check
   u = @c_user
   area = fetch_area(0)
   hash = email_lookup_table(area.tbl,u.name)
   total =  e_total(area.tbl,u.name)
   #puts "inp:#{inp}"
  if inp > 0 and inp <= max and total > 0 then
   epointer = inp
   displaymessage(hash[epointer - 1],area.tbl,true)
  else print "Out of Range" end
  epointer
 end 
 
 def nextmail(epointer)
 
 ptr_check
 u = @c_user
 area = fetch_area(0)
 hash = email_lookup_table(area.tbl,u.name)
 total =  e_total(area.tbl,u.name)
 #puts "epointer: #{epointer}"
 #puts "total: #{total}"
 #puts "hash: #{hash}"
 
  if epointer < total and total > 0 then
   epointer +=1
   displaymessage(hash[epointer - 1],area.tbl,true)
  else
   print("No More Email")
  end
  return epointer
 end
 
 def lastmail(epointer)
 
 ptr_check
 u = @c_user
 area = fetch_area(0)
 hash = email_lookup_table(area.tbl,u.name)
 total =  e_total(area.tbl,u.name)
 #puts "epointer: #{epointer}"
 #puts "total: #{total}"
 #puts "hash: #{hash}"
 
  if epointer > 1 then
   epointer -=1
   displaymessage(hash[epointer - 1],area.tbl,true)
  else
   print("No More Email")
  end
  return epointer
 end
 
 def reademail(new)
   area = fetch_area(0)
   ptr_check
   u = @c_user
   hash = email_lookup_table(area.tbl,u.name)
   p_area = @c_area
   epointer = 0
  @c_area = 0
  @who.user(@c_user).where="Reading Email"
   #puts "lastread: #{u.lastread[0]}"
   #puts "hash: #{hash}"
   if new then
    epointer = find_epointer(hash,u.lastread[0],area.tbl,u.name)
    #puts "result #{epointer}"
    if epointer == nil then epointer = 0 else epointer += 1 end
   else
    epointer = 1 if e_total(area.tbl,u.name) > 0
   end
   if epointer < 1 then 
    print "You have no email."
    @c_area = p_area
    return
   end
   #puts "epointer: #{epointer}"
   displaymessage(hash[epointer - 1],area.tbl,true)
   done = false
   getinp("%M( -, R, K, /, F, Q, N, ?): ",false) {|inp|
			happy = inp.upcase.strip 
			if !happy.integer? 
				happy.gsub!(/[-\d]/,"")
				happy = "" if happy == "N"
			end
			case happy
			when ""; epointer = nextmail(epointer)
			when "G"; leave

			when "R"; replyemail(epointer,0)
			when "?"; write "%W"; gfileout ("emailmnu")
			when "/"; displaymessage(hash[epointer - 1],area.tbl,true)
			when "K"; deletemessage(epointer)
			when "Q"; done = true # exit input loop
			else; print "Out of Range."
			end #of case 
			done
		}
		@c_area = p_area
 end 

 def deletemessage(epointer)
 
  u = @c_user
  area = fetch_area(0)
  hash = email_lookup_table(area.tbl,u.name)
  total = e_total(area.tbl,u.name)
  del = hash[epointer - 1]
  
  if total > 0 then
   delete_msg(area.tbl,del)
  print "Email ##{epointer} [#{del}] deleted."
  ptr_check
 else 
  print; print "No Messages"
 end
end



 
 def qwkmailadr(address)
  
  to = nil;route = nil
  if !address.index(".") then
  happy =  (/^(.+)@([a-z,A-Z]+)/) =~ address
  if happy then
   to = $1;route = $2
  end
 end
  return [to,route]
 end
 
 def stmpmailadr(address)
  happy =  (/^(.+)@(.+)\.(.+)/) =~ address
  if happy then return true else return false end
 end
 
 def netmailadr(address)
  
  to = nil;zone = nil;net = nil;node = nil;point = nil
  happy =  (/^(.*)@(\d?):(\d{1,4})\/(.*)/) =~ address
  if happy then
   to = $1;zone = $2;net = $3;node = $4
   grumpy = (/(\d{1,4})\.(\d{1,4})/) =~ node
   if grumpy then
    node = $1;point = $2
   end
 
  end
  return [to,zone,net,node,point]
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
 
 def findlocal(user)

  if user_exists(user) then 
   return true
  else 
   return false
  end
 end
 
 def smtp_send(to,from,subject,message)
  msgstr = message.join("\n")
  from_smtp = "#{from.gsub(" ",".")}@#{SMTPDOMAIN}"
  msg = [ "From: #{from_smtp}\n","To: #{to}\n","Subject: #{subject}\n", "\n", "#{msgstr}" ]
  Net::SMTP.start(SMTPSERVER, 25) do |smtp|
      smtp.send_message msg, from_smtp, to
    end
 end
 
 def sendemail(feedback)
 
 to = nil;zone = nil;net = nil;node = nil;point = nil
 
  if @c_user.areaaccess[@c_area] =~ /[RN]/
   print "%RYou do not have permission to send Email."
   return
  end
  print
  if !feedback then

   while true
    inp = getinp("%CTo: ",false) 
    inp.strip!
    to,zone,net,node,point = netmailadr(inp)
    return if inp == ""
    if !to.nil? then
     print "Sending a Netmail Message to: #{inp}"
     m_type = F_NETMAIL
     to.upcase!
     break
    end
    to,route = qwkmailadr(inp)
    if !to.nil? then
     print "Sending a QWK Netmail Message to: #{inp}"
     m_type = Q_NETMAIL
     to.upcase!
     break
    end
    smtp = stmpmailadr(inp)
    if smtp then 
     print "Sending a SMTP (Internet Email) Message to: #{inp}"
     to = inp
     m_type = SMTP
     break
    end
    if !findlocal(inp) then
     print "%RLocal User not found..."
    else 
     to = inp.upcase
     m_type = LOCAL
     break
    end
   end
 
  else 
   to = SYSOPNAME  # because it's feedback.  
  end
  #to.upcase!
  to.strip!
  title = getinp("%GTitle: ",false).strip
  return false if title == "" 
  reply_text = ["***No Message to Quote***"]
 # m_type = LOCAL
    if @c_user.fullscreen then
      write "%W"
      msg_file = write_quote_msg("")
      launch_editor(msg_file)
      suck_in_text(msg_file)
      prompt = "Send email (Y,n)? "
      saveit = yes(prompt, true, false,true)
     else
      saveit = lineedit(1,reply_text)
      puts saveit
      puts "m_type=#{m_type}"
     end
     if saveit then
      case m_type
       when LOCAL
        savecurmessage(0, to, title, false,false,nil,nil,nil,nil) 
        print "Sending Local e-mail..."
	
       when F_NETMAIL
         table,number = find_fido_area(NETMAIL)
         intl = "#{zone}:#{net}/#{node} #{FIDOZONE}:#{FIDONET}/#{FIDONODE}" 
         savecurmessage(number,to,title,false,false,node,net,intl,point)
         print "Sending Netmail..."
       
       when Q_NETMAIL
        number = find_qwk_area(QWKMAIL,nil)
        if route.upcase != BBSID then
         @lineeditor.msgtext.unshift(inp)
         to = "NETMAIL"
        end
        savecurmessage(number,to,title,false,false,nil,nil,nil,nil)
        print "Sending QWK Netmail..."
       when SMTP
        print "Sending SMTP (Internet) Email..."
	smtp_send(to,@c_user.name,title,@lineeditor.msgtext)
	#send_smtp
       
       end #of case
     end
 end # of def sendemail

 def replyemail(epointer,carea)
  area = fetch_area(carea)
  u = @c_user
  if carea > 0 then
   abs = absolute_message(area.tbl,epointer)
   r_message = fetch_msg(area.tbl, abs)
  else
   hash = email_lookup_table(area.tbl,u.name)
   r_message = fetch_msg(area.tbl, hash[epointer - 1] )
  end
  msg_text = []
  # r_message.msg_text.each('ã') {|line| msg_text.push(line.chop!)}
  r_message.msg_text.each(DLIM) {|line| msg_text.push(line.chop!)}
  done = false
  print
  if %w(R N).include?(@c_user.areaaccess[0])
   print "%RYou do not have write access."
   return false
  end
  m_type = LOCAL
  to = r_message.m_from.strip
  title = r_message.subject
  if r_message.f_network then
   happy = (/(.*) (.*)/) =~ r_message.intl
   r_intl = $2
   print "Replying to: #{to} (#{r_intl})"
   zone,net,node,point = parse_intl(r_intl)
   if zone.nil? then
    zone = FIDOZONE
    net = r_message.orgnet
    node = r_message.orgzone
   end
   intl = "#{zone}:#{net}/#{node} #{FIDOZONE}:#{FIDONET}/#{FIDONODE}" 
   m_type = F_NETMAIL
  end
  if r_message.network then
   msg_text,msgid,via,tz,reply = qwk_kludge_search(msg_text)
   out = BBSID
   out = via if !via.nil?
   print "Replying to: %W#{to}@#{out}"
   m_type = Q_NETMAIL
  end
  if r_message.smtp then
   m_type = SMTP
  end
  msg_text.unshift("--- #{to} wrote ---")
  for x in 0..msg_text.length - 1 do
   msg_text[x] = "> #{msg_text[x].chop!}"
  end
  print "%GTitle: #{title}"
  prompt = "%REnter New Subject or %W %Y<--^%W: "
  tempstr = getinp(prompt,false) {|inp|
				tempstr = inp.strip
				tempstr.upcase == "CR" ? crerror : true
					}
  title = tempstr if tempstr != ""
    if @c_user.fullscreen then
      write "%W"
      msg_file = write_quote_msg(msg_text)
      launch_editor(msg_file)
      suck_in_text(msg_file)
       print (CLS)
      prompt = "Send message (Y,n)? "
      saveit = yes(prompt, true, false,true)
     else
      saveit = lineedit(1,msg_text)
     end
  if saveit then
   case m_type
    when F_NETMAIL
     table,number = find_fido_area(NETMAIL)
     savecurmessage(number, to, title, false,false,node,net,intl,point) 
     print "Sending Netmail..."
   when Q_NETMAIL
     number = find_qwk_area(QWKMAIL,nil)
     if !via.nil? then
      @lineeditor.msgtext.unshift("#{to}@#{via}")
      to = "NETMAIL"
      
     end
     print "Sending QWK Netmail..."
     savecurmessage(number, to, title, false,false,node,net,intl,point) 
   when SMTP
    print "Sending SMTP (Internet) Email..."
    smtp_send(to,@c_user.name,title,@lineeditor.msgtext)
   when LOCAL
    savecurmessage(0, to, title, false,false,nil,nil,nil,nil) 
    print "Sending Local e-mail..."
   end
  end
 end

	def email
		prompt ="[R]ead [S]end [Q]uit: "
		getinp(prompt,false) {|inp|
			happy = inp.upcase.strip 
			parameters = Parse.parse(happy)
			happy.gsub!(/[-\d]/,"")
			case happy
			when "Q"; done = true
			when "R"; reademail(false)
			when "S"; gfileout ("emailsnd");sendemail(false)
			end 
			done
		}
	end 
end
