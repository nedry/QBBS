##############################################
#											
#   nntp.rb --NNTP connector for QBBS.		                                
#   (C) Copyright 2012, Fly-By-Night Software (Ruby Version)                        
#                                                                                                            
##############################################

#!/usr/bin/ruby
$LOAD_PATH << "."

require 'consts.rb'
require 'dm-core'
require 'dm-validations'
require 'dm-aggregates'
require "db/db_area"
require "db/db_bulletins"
require "db/db_message"
require "db/db_doors"
require "db/db_bbs"
require "db/db_system"
require "db/db_themes"
require "db/db_who"
require "db/db_who_telnet.rb"
require "db/db_wall.rb"
require "db/db_log.rb"
require "db/db_groups"
require "db/db_user"
require "db/db_screen"
require "message.rb"
require "iconv"
require "socket"


NNTP_PORT = "119"
NNTP_INITIAL_DOWNLOAD = 500


def open_nntp(host, port)

  begin
    @sock = TCPSocket.open(host, port)
    puts "-NNTP: #{nntp_recv}"
    return true
  rescue
    puts "-Error: cannot resolve NNTP server."
    return false
  end
 end

def nntp_send(message)
  if message
    @sock.send("#{message}\r\n", 0)
  end
end

def nntp_recv  # Get the next line from the socket.
      
  reply = @sock.gets

  if reply
    reply.strip!
  end

  return reply

end

    # Shuts down the receive (how == 0), or send (how == 1), or both
    # (how == 2), parts of this socket.
    
def nntp_shutdown(how=2)
  @sock.shutdown(how)
end

def nntp_login(user,password)
  success = false
  nntp_send ("AUTHINFO USER #{user}")
  puts "-NNTP: #{nntp_recv}"
  nntp_send ("AUTHINFO PASS #{password}")
  result = nntp_recv
  puts "-NNTP: #{result}"
  if !result.nil?
    success = true if result[0] == "2" 
  end
end

def nntp_setgroup(groupname)
  success = false
  nntp_send ("GROUP #{groupname}")
  result = nntp_recv
  puts "-NNTP: #{result}"
  if !result.nil? 
    success = true if result[0] == "2"
    params = result.split
    #params returncode, total articles, first article, last article
    return [success,params[1].to_i,params[2].to_i,params[3].to_i]
  end
end

def nntp_getarticle(artnum)

 article = []
 done = false
 #puts "ARTICLE #{artnum}"
 nntp_send("ARTICLE #{artnum}")
 while !done 
   line = nntp_recv
   article << line
   done = true if line == "." 
   if line == "423 no such article in group" then
    puts "-NNTP: Article #{artnum} missing."
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
      when "WhenImported"
      when "WhenExported"
      when "ExportedFrom"
      when "User-Agent"
      when "Mime-Version"
      when "Injection-Date"
      when "Injection-Info"
      when "Cancel-Lock"
      when "X-Usenet-Provider"
      when "X-DMCA-Notifications"
      when "X-Abuse-and-DMCA-Info"
      when "X-Postfilter"
      when "X-Antivirus"
      when "X-Antivirus-Status"
      when "X-Remailer-Contact"
      when "X-UC-Weight"
      when "X-UC-Weight"
      when "Mail-To-News-Contact"

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
      when "X-Complaints-To"
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
      when "Reply-to"
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
      else
	msgbody << article[i]
     end #of case
   else
    msgbody << article[i]   
   end
  end
  puts "--- header ---"
  puts "messageto: #{messageto}" if !messageto.nil?
  puts "apparentlyto: #{apparentlyto}" if !apparentlyto.nil?
  puts "path: #{path}" if !path.nil?
  puts "newsgroups: #{newsgroups}" if !newsgroups.nil?
  puts "xcommentto: #{xcommentto}" if !xcommentto.nil?
  puts "from: #{from}" if !from.nil?
  puts "organization: #{organization}" if !organization.nil?
  puts "replyto: #{replyto}" if !replyto.nil? 
  puts "inrepyto: #{inrepyto}" if !inrepyto.nil?
  puts "datetime: #{datetime}" if !datetime.nil?
  puts "subject: #{subject}" if !subject.nil? 
  puts "messageid: #{messageid}" if !messageid.nil?
  puts "references: #{references}" if !references.nil? 
  puts "xgateway: #{xgateway}" if !xgateway.nil?
  puts "xftnpid: #{ftnpid}" if !ftnpid.nil?
  puts "xftntid: #{ftntid}" if !ftntid.nil?
  puts "xftnarea: #{ftnarea}" if !ftnarea.nil? 
  puts "xftnflags: #{ftnflags}" if !ftnflags.nil? 
  puts "xftnmsgid: #{ftnmsgid}" if !ftnmsgid.nil? 
  puts "xftnreply: #{ftnreply}" if !ftnreply.nil?
  puts "control: #{control}" if !control.nil?	
  puts "lines: #{lines}" if !lines.nil?
  puts "bytes: #{bytes}" if !bytes.nil?
  puts "xref: #{xref}" if !xref.nil?
  puts "xcommentto: #{xcommentto}" if !xcommentto.nil?
  puts "contenttype: #{contenttype}" if !contenttype.nil?
  puts "contenttransferencoding: #{contenttransferencoding}" if !contenttransferencoding.nil?
  puts "xgateway: #{xgateway}" if !xgateway.nil?
  puts "nntppostinghost: #{nntppostinghost}" if !nntppostinghost.nil?
  puts "xcomplaintsto: #{xcomplaintsto}" if !xcomplaintsto.nil?
  puts "xtrace: #{xtrace}" if !xtrace.nil?
  puts "nntppostingdate: #{nntppostingdate}" if !nntppostingdate.nil?
  puts "xoriginalbytes: #{xoriginalbytes}" if !xoriginalbytes.nil?
  puts "charset: #{charset}" if !charset.nil? 
  puts "xcomplaints: #{xcomplaints}" if !xcomplaints.nil?  

  puts "----------"
  puts
 
  msgbody.pop  #remove last line, which is the end of message char
  

  
  untrusted_string = msgbody.join(DLIM)
  
  ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')
  msg_text = ic.iconv(untrusted_string + ' ')[0..-2]
  

  
  absolute = add_nntp_msg(to,from,datetime,subject,msg_text,area.number, apparentlyto,
                 xcommentto, newsgroups, path, organization, replyto,
                 inreplyto, lines, bytes, xref, messageto, references, xgateway,
                 control, charset, contenttype, contenttransferencoding,
                 nntppostinghost, xcomplaintsto, xtrace, nntppostingdate,
                 xoriginalbytes, ftnarea, ftnflags, ftnmsgid, ftnreply,
		 ftntid, ftnpid)
  return absolute
end

def makenntpimportlist(group)
 list = nntp_list(group.grp)
 puts "-NNTP: The following areas have NNTP mappings..."
 list.each {|x| puts "     #{x.nntp_net}.........#{x.name}" }
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
	   puts "-NNTP: total articles #{total}"
           puts "-NNTP: first article #{first}"
           puts "-NNTP: last article #{last}"
	   puts "-NNTP: area pointer #{area.nntp_pointer}"
	   pointer = set_pointer(area.nntp_pointer,first,last,total)
	   if pointer < last then
	     for i in pointer..last
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
	  puts "-ERROR: Group not found." #add loging
	 end
	}
     else
       puts "-ERROR: NNTP logon Failure"  #add logging
     end
     nntp_shutdown
   else
    puts "-ERROR: NNTP Server connection failure." #add logging
  end
 end
end

def nntp_down
  
  puts "-NNTP: scanning for export groups."
  for i in 0..g_total-1
    group = fetch_group(i)
     if get_nntpnet(group).nil? then
      puts "-NNTP: group #{i} #{group.groupname} has no NNTP."
    else
      puts "-NNTP: group #{i} #{group.groupname} has NNTP."
      group_down(group)
     end
  end
end




DataMapper::Logger.new('log/db', :debug)
DataMapper.setup(:default, "postgres://#{DATAIP}/#{DATABASE}")
DataMapper.finalize

nntp_down

