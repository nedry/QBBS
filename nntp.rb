##############################################
#											
#   nntp.rb --NNTP connector for QBBS.		                                
#   (C) Copyright 2012, Fly-By-Night Software (Ruby Version)                        
#                                                                                                            
##############################################

#!/usr/bin/ruby
$LOAD_PATH << "."

#require "iconv"
require "socket"


NNTP_PORT = "119"
NNTP_INITIAL_DOWNLOAD = 500


def open_nntp(host, port)

  begin
    @socket = TCPSocket.open(host, port)
    @debuglog.push( "-NNTP: #{nntp_recv}")
    return true
  rescue
    @debuglog.push( "-Error: cannot resolve NNTP server.")
    return false
  end
 end

def nntp_send(message)
  if message
    @socket.send("#{message}\r\n", 0)
  end
end

def nntp_recv  # Get the next line from the socket.
      
  reply = @socket.gets

  if reply
    reply.strip!
  end

  return reply

end

    # Shuts down the receive (how == 0), or send (how == 1), or both
    # (how == 2), parts of this socket.
    
def nntp_shutdown(how=2)
  @socket.shutdown(how)
end

def nntp_login(user,password)
  success = false
  if user != "" then  #some servers don't require uid/password 

  nntp_send ("AUTHINFO USER #{user}")
  @debuglog.push( "-NNTP: #{nntp_recv}")
  nntp_send ("AUTHINFO PASS #{password}")
  result = nntp_recv
  @debuglog.push( "-NNTP: #{result}")
  if !result.nil?
    success = true if result[0] == "2" 
  end
else
  success = true
end
end

def nntp_setgroup(groupname)
  success = false
  nntp_send ("GROUP #{groupname}")
  result = nntp_recv
  @debuglog.push( "-NNTP: #{result}")
  if !result.nil? 
    success = true if result[0] == "2"
    params = result.split
    #params returncode, total articles, first article, last article
    return [success,params[1].to_i,params[2].to_i,params[3].to_i]
  end
end

def nntp_getarticle(artnum)

 article = []
 count = 0
 done = false
 nntp_send("ARTICLE #{artnum}") if !artnum.nil?
 while !done 
   line = nntp_recv
	 @debuglog.push( "-NNTP: #{line}")
   article << line
	 count = count + 1
   done = true if line == "." 
	 #we only want to look for a article missing error on the first line of a response
   if line[0] == "4" and count == 1 then
    @debuglog.push( "-NNTP: Article #{artnum} missing.")
    done = true
    article = nil
   end
 end
 return article
end



def nntp_parsearticle(article,area)
  article.slice!(0)  #remove first line which is the server response.

  msgbody = []
  path = nil
  newsgroups = nil
  xcommentto = nil
  from = nil
  organization = nil
  replyto = nil
  inreplyto = nil
  datetime = nil
  subject = nil
  messageid = nil
  references = nil
  xgateway = nil
  ftnpid = nil
  ftntid = nil
  ftnarea = nil
  ftnflags = nil
  ftnmsgid = nil
  ftnreply = nil
  control = nil
  lines = nil
  bytes = nil
  xref = nil
  xcommentto = nil
  contenttype = nil
  contenttransferencoding = nil
  xgateway = nil
  nntppostinghost = nil
  xcomplaintsto = nil
  xtrace = nil
  nntppostingdate = nil
  xoriginalbytes = nil 
  apparentlyto = nil
  messageto = nil
  charset = nil
  xcomplaints = nil

  header = true
   
  for i in 0..article.length-1
    header = false if article[i].strip == ""
    match = (/^(\S+)\:(.*)/) =~ article[i]  
    if match and header then    

    case $1
			#these can all go when we're sure we aren't missing any header goodness
			#and we can just drop any unknown header lines
      when "WhenImported", "WhenExported", "ExportedFrom", "User-Agent"
      when "Mime-Version", "Injection-Date", "Injection-Info", "Cancel-Lock"
      when "X-Usenet-Provider", "X-DMCA-Notifications", "X-Abuse-and-DMCA-Info"
      when "X-Postfilter", "X-Antivirus", "X-Antivirus-Status", "X-Priority"
      when "X-Remailer-Contact", "X-UC-Weight", "Mail-To-News-Contact"
			when "X-HTTP-UserAgent", "MIME-Version", "MIME-Version", "X-MimeOLE"
			when "X-MSMail-Priority", "X-Newsreader","X-newsreader", "Received"
			when "X-AuthenticatedUsername", "X-Orig-Path", "X-Received-Bytes"
			when "Distribution", "Sender"
			
      when "Message-To"
        messageto = $2
      when "Charset"
        charset = $2
      when "Apparently-To"
        apparentlyto = $2
      when "X-Comment-To"
        xcommentto = $2
      when "X-Complaints"
        xcomplaints = $2
      when "Content-Type"
        contenttype = $2
      when "Content-Transfer-Encoding"
        contenttransferencoding = $2
      when "X-Gateway"
        xgateway = $2
      when "NNTP-Posting-Host"
        nntppostinghost = $2
      when "X-Complaints-To", "Complaints-To"
        xcomplaintsto = $2
      when "X-Trace"
        xtrace =$2
      when "NNTP-Posting-Date"
        nntppostingdate = $2
      when "X-Original-Bytes"
        xoriginalbytes = $2
      when "Lines"
        lines = $2.to_i
      when "Bytes"
	      bytes = $2.to_i
      when "Xref"
        xref = $2
      when "To"
        to = $2
      when "Path"
        path = $2
      when "Newsgroups"
        newsgroups = $2
      when "X-comment-to"
        xcommentto = $2
      when "From"
        from = $2
	      from.gsub!(/\.remove-\S+-this/,"")
      when "Organization"
        organization = $2
      when "Reply-To"
        replyto = $2
      when "In-Reply-To"
        inrepyto = $2
      when "Date"
        datetime = $2
      when "Subject"
	      subject = $2
      when "Message-ID"
        messageid = $2
      when "References"
        references = $2
      when "X-gateway"
        xgateway = $2
      when "X-FTN-PID"
        ftnpid = $2
      when "X-FTN-TID"
        ftntid = $2
      when "X-FTN-AREA"
        ftnarea = $2
      when "X-FTN-FLAGS"
	ftnflags = $2
      when "X-FTN-MSGID"
        ftnmsgid = $2
      when "X-FTN-REPLY"
        ftnreply = $2
      when "Control"
        control = $2
     # else
	#msgbody << article[i]
     end #of case
   else
    msgbody << article[i]   
   end
  end
  #puts "--- NNTP Import ---"
  #puts "messageto:                  #{messageto}" if !messageto.nil?
  #puts "apparentlyto:               #{apparentlyto}" if !apparentlyto.nil?
  #puts "path:                       #{path}" if !path.nil?
  #puts "newsgroups:                 #{newsgroups}" if !newsgroups.nil?
  #puts "xcommentto:                 #{xcommentto}" if !xcommentto.nil?
  #puts "from:                       #{from}" if !from.nil?
  #puts "organization:               #{organization}" if !organization.nil?
  #puts "replyto:                    #{replyto}" if !replyto.nil? 
  #puts "inrepyto:                   #{inrepyto}" if !inrepyto.nil?
  #puts "datetime:                   #{datetime}" if !datetime.nil?
  #puts "subject:                    #{subject}" if !subject.nil? 
  #puts "messageid:                  #{messageid}" if !messageid.nil?
  #puts "references:                 #{references}" if !references.nil? 
  #puts "xgateway:                   #{xgateway}" if !xgateway.nil?
  #puts "xftnpid:                    #{ftnpid}" if !ftnpid.nil?
  #puts "xftntid:                    #{ftntid}" if !ftntid.nil?
  #puts "xftnarea:                   #{ftnarea}" if !ftnarea.nil? 
  #puts "xftnflags:                  #{ftnflags}" if !ftnflags.nil? 
  #puts "xftnmsgid:                  #{ftnmsgid}" if !ftnmsgid.nil? 
  #puts "xftnreply:                  #{ftnreply}" if !ftnreply.nil?
  #puts "control:                    #{control}" if !control.nil?	
  #puts "lines:                      #{lines}" if !lines.nil?
  #puts "bytes:                      #{bytes}" if !bytes.nil?
  #puts "xref:                       #{xref}" if !xref.nil?
  #puts "xcommentto:                 #{xcommentto}" if !xcommentto.nil?
  #puts "contenttype:                #{contenttype}" if !contenttype.nil?
  #puts "contenttransferencoding:    #{contenttransferencoding}" if !contenttransferencoding.nil?
  #puts "xgateway:                   #{xgateway}" if !xgateway.nil?
  #puts "nntppostinghost:            #{nntppostinghost}" if !nntppostinghost.nil?
  #puts "xcomplaintsto:              #{xcomplaintsto}" if !xcomplaintsto.nil?
  #puts "xtrace:                     #{xtrace}" if !xtrace.nil?
  #puts "nntppostingdate:            #{nntppostingdate}" if !nntppostingdate.nil?
  #puts "xoriginalbytes:             #{xoriginalbytes}" if !xoriginalbytes.nil?
  #puts "charset:                    #{charset}" if !charset.nil? 
  #puts "xcomplaints:                #{xcomplaints}" if !xcomplaints.nil?  

  #puts "----------"
  #puts
 
 # msgbody.pop  #remove last line, which is the end of message char
  
#remove any illegal characters... 
  
  msg_string = msgbody.join(DLIM)
  msg_text = nntp_convert(msg_string)
	subject = nntp_convert(subject)
	from = nntp_convert(from)
	
	if area.nil? and !newsgroups.nil? then
	  area = fetch_mbbs_area(newsgroups.strip)
		@debuglog.push("-NNTP: Found area for message: #{area}")
		datetime = Time.now.strftime("%Y-%m-%d %I:%M%p") if datetime.nil?
  end
	
  organization = "" if organization.nil?
  if (organization.strip != SYSTEMNAME.strip) and !area.nil? then
  
    absolute = add_nntp_msg(to,from,datetime,subject,msg_text,area.number, apparentlyto,
                 xcommentto, newsgroups, path, organization, replyto,
                 inreplyto, lines, bytes, xref, messageto, references, xgateway,
                 control, charset, contenttype, contenttransferencoding,
                 nntppostinghost, xcomplaintsto, xtrace, nntppostingdate,
                 xoriginalbytes, ftnarea, ftnflags, ftnmsgid, ftnreply,
		             ftntid, ftnpid, messageid)
  else
		"-NNTP: Dropping article it's from us!"
		absolute = nil
	end
  return absolute
end

def makenntpimportlist(group)
 list = nntp_list(group.grp)
 @debuglog.push( "-NNTP: The following areas have NNTP mappings...")
 list.each {|x| @debuglog.push( "     #{x.nntp_net}.........#{x.name}") }
 return list
end

def set_pointer(pointer,first,last,total)
  if pointer == 0 then
    pointer = last - NNTP_INITIAL_DOWNLOAD
    pointer = first if pointer < first
  end
  return pointer
end

def group_down(group)
 import = makenntpimportlist(group)
 if import.length > 0 then
   nntpnet = get_nntpnet(group)
   if open_nntp(nntpnet.nntpaddress, NNTP_PORT) then
     if nntp_login(nntpnet.nntpaccount,nntpnet.nntppassword) then

			import.each {|area| 
				user = fetch_user(get_uid(nntpnet.nntpuser))
				scanforaccess(user)  #insures that pointers get set if this has never been run b4
				upointer = get_pointer(user,area.number)
				result,total,first,last = nntp_setgroup(area.nntp_net)
				if result then
					@debuglog.push("-NNTP: total articles #{total}")
					@debuglog.push( "-NNTP: first article #{first}")
					@debuglog.push("-NNTP: last article #{last}")
					@debuglog.push("-NNTP: area pointer #{area.nntp_pointer}")
					pointer = set_pointer(area.nntp_pointer,first,last,total)
					pointer = 0 if pointer.nil?
					if pointer < last then
						for i in pointer+1..last
							article = nntp_getarticle(i)
							if !article.nil? then
								absolute = nntp_parsearticle(article,area)
								area.nntp_pointer = i
								update_area(area)
								user.posted = user.posted + 1
								upointer.lastread = absolute
								update_pointer(upointer)
								update_user(user)
							end
						end
					end
				else
				@debuglog.push("-ERROR: Group not found.") #add loging
			end
	}
     else
       @debuglog.push( "-ERROR: NNTP logon Failure")  #add logging
     end
     nntp_shutdown
   else
    @debuglog.push("-ERROR: NNTP Server connection failure.") #add logging
  end
end

end

def nntp_down
  
  @debuglog.push( "-NNTP: scanning for export groups.")
  for i in 0..g_total-1
    group = fetch_group(i)
     if get_nntpnet(group).nil? then
      @debuglog.push( "-NNTP: group #{i} #{group.groupname} has no NNTP.")
    else
      @debuglog.push( "-NNTP: group #{i} #{group.groupname} has NNTP.")
      group_down(group)
     end
  end
end

def nntp_messageid
  sysname = SYSTEMNAME.gsub(" ","")
  o =  [('a'..'z'),('A'..'Z')].map{|i| i.to_a}.flatten;  
  noise   =  (0..20).map{ o[rand(o.length)]  }.join;
  "#{noise}@#{sysname}"
end

def nntp_writemessage_post(msg,newsgroup,tag)
  from = "\"#{msg.m_from}\" <#{msg.m_from.gsub(" ",".")}@#{SYSTEMNAME.gsub(" ",".")}>"
	nntp_send("From: #{from}")
	nntp_send("Newsgroups: #{newsgroup}")
	nntp_send("Subject: #{msg.subject}")
	nntp_send("Organization: #{SYSTEMNAME}")
	nntp_send("References: #{msg.nntpreferences}") if !msg.nntpreferences.nil?
	tempmsg=convert_to_ascii(msg.msg_text)
	tempmsg.each_line(DLIM) {|line| nntp_send("#{line.sub(/^\./, '..').chop}")}
	nntp_send("--- #{NNTP_TAG}")
	nntp_send(tag)
	nntp_send(".\r\n")
end

def nntp_ihave(absolute)
	msgid="#{absolute}#{nntp_messageid}"
	nntp_send("IHAVE #{msgid}")
	response = nntp_recv
	if response[0] == "3" then
		@debuglog.push( "-NNTP: Server will accept message #{absolute}")
		@debuglog.push(nntp_recv)
		return msgid
	else
		@debuglog.push( "-NNTP: NNTP_PORTServer says no! #{absolute}")
		return nil
	end
end

def nntp_post

	nntp_send("POST")
	response = nntp_recv
	if response[0] == "3" then
		@debuglog.push( "-NNTP: Server will accept message.")
		return true
	else
		@debuglog.push( "-NNTP: NNTP_PORTServer says no! #{absolute}")
		return false
	end
end

def nntp_export(group)
		nntpnet = get_nntpnet(group)
   if open_nntp(nntpnet.nntpaddress, NNTP_PORT) then
     if nntp_login(nntpnet.nntpaccount,nntpnet.nntppassword) then
  ddate = Time.now.strftime("%m/%d/%Y at %I:%M%p")
  @debuglog.push( "-NNTP: Starting export.")
	add_log_entry(3,Time.now,"Starting QWK message export.")
  total = 0
  nntp_list(group.grp).each {|xp|
  @debuglog.push( "-NNTP: Now Processing #{xp.name} message area.")

  user = fetch_user(get_uid(nntpnet.nntpuser))

    scanforaccess(user)
    pointer = get_pointer(user,xp.number)       
       
    @debuglog.push( "-NNTP: Last [absolute] Exported Message...#{pointer.lastread}")
    @debuglog.push( "-NNTP: Highest [absolute] Message.........#{high_absolute(xp.number)}")
    @debuglog.push("-NNTP: Total Messages.....................#{m_total(xp.number)}")
    new = new_messages(xp.number,pointer.lastread)
    @debuglog.push("-NNTP: Messages to Export..................#{new}")
	   
		if new > 0 then

	  export_messages(xp.number,pointer.lastread).each {|msg|

			if  !msg.usenet_network then 
			  if nntp_post then
					nntp_writemessage_post(msg,xp.nntp_net,nntpnet.nntptag)
					@debuglog.push(nntp_recv)
		      total += 1
		      msg.exported = true
	        update_msg(msg)
					pointer.lastread = high_absolute(xp.number)
					update_pointer(pointer)
				else
					@debuglog.push("-NNTP: Some sort of funky send error: #{nntp_recv}")
				end
			else
        error = msg.usenet_network ?
          "Message has already been imported.":
          "Message [#{msg.absolute}] doesn't exist."
          m = "Message #{msg.absolute} not exported.  #{error}"
          @debuglog.push( "-#{m}")
          add_log_entry(L_EXPORT,Time.now,"NNTP Export Complete.")
	     end
	}
            end
            @debuglog.push("-NNTP: Updating message pointer for board #{xp.name}")

         # end

      }
      add_log_entry(L_EXPORT,Time.now,"Export Complete. #{total} message(s) exported.")
      @debuglog.push( "-NNTP: Export Complete. #{total} message(s) exported.")
     

     else
       @debuglog.push( "-ERROR: NNTP logon Failure")  #add logging
     end
     nntp_shutdown
   else
    @debuglog.push( "-ERROR: NNTP Server connection failure.") #add logging
  end
end

def nntp_up

  @debuglog.push( "-NNTP: scanning for NNTP import groups.")
  for i in 0..g_total-1
    group = fetch_group(i)
     if get_nntpnet(group).nil? then
      @debuglog.push( "-NNTP: group #{i} #{group.groupname} has no NNTP.")
    else
      @debuglog.push( "-NNTP: group #{i} #{group.groupname} has NNTP.")
      nntp_export(group)
     end
	 end

 end


