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


class A_nntp_message  		# An individual Fidonet Message


 def initialize (apparentlyto,to, xcommentto,newsgroups,path,
		 from,organization,replyto,inreplyto,datetime,subject,
		 lines,bytes,xref,messageto,references,xgateway,control,charset,
		 contenttype, contenttransferencoding,  
		 nntppostinghost, xcomplaints, xtrace, nntppostingdate, xoriginalbytes,
		 ftnarea,ftnflags,ftnmsgid,ftnpid, ftntid, ftnreply,message)
  @to				= to
  @apparentlyto			= apparentlyto
  @xcommentto			= xcommentto
  @newsgroups			= newsgroups
  @path				= path
  @from				= from
  @organization			= organization
  @replyto			= replyto
  @inreplyto			= inreplyto
  @datetime			= datetime
  @subject			= subject
  @lines			= lines
  @bytes			= bytes
  @xref				= xref
 
  @messageto			= messageto
  @references			= references
  @xgateway			= xgateway
  @control			= control
  @charset			= charset

  @contenttype 			= contenttype
  @contenttransferencoding 	= contenttransferencoding
  @nntppostinghost 		= nntppostinghost
  @xcomplaintsto 		= xcomplaintsto
  @xtrace 			= xtrace
  @nntppostingdate 		= nntppostingdate
  @xoriginalbytes 		= xoriginalbytes

  @ftnarea			= ftnarea
  @ftnpid			= ftnpid
  @ftntid			= ftntid
  @ftnarea			= ftnarea
  @ftnflags			= ftnflags
  @ftnmsgid			= ftnmsgid
  @ftnreply			= ftnreply
  
  @message			= message 
end
 
 attr_accessor 	:apparentlyto, :to, :xcommentto, :newsgroups, :path,
		:from, :organization, :replyto, :inreplyto, :datetime, :subject,
		:lines, :bytes, :xref, :messageto, :references, :xgateway, :control, :charset, 
		:contenttype, :contenttransferencoding, :nntppostinghost,
		:xcomplaintsto, :xtrace, :nntppostingdate, :xoriginalbytes, :ftnarea,
		:ftnflags, :ftnmsgid, :ftnpid, :ftntid, :ftnreply, :message
	 
	 
end # of class A_nntp_message

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
 puts "ARTICLE #{artnum}"
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
  limit = article.length 
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


   
  for i in 0..limit
    match = (/^(\S+)\:(.*)/) =~ article[i]  
    if match then    

    case $1
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
      when "X-ftn-pid"
        ftnpid = $2
      when "X-ftn-tid"
        ftntid = $2
      when "X-ftn-area"
        ftnarea = $2
      when "X-ftn-flags"
	ftnflags = $2
      when "X-ftn-msgid"
        ftnmsgid = $2
      when "X-ftn-reply"
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
  puts "messageto: #{messageto}"
  puts "apparentlyto: #{apparentlyto}"
  puts "path: #{path}"
  puts "newsgroups: #{newsgroups}"
  puts "xcommentto: #{xcommentto}"
  puts "from: #{from}"
  puts "organization: #{organization}"
  puts "replyto: #{replyto}" 
  puts "inrepyto: #{inrepyto}"
  puts "datetime: #{datetime}"
  puts "subject: #{subject}" 
  puts "messageid: #{messageid}"
  puts "references: #{references}" 
  puts "xgateway: #{xgateway}"
  puts "xftnpid: #{ftnpid}"
  puts "xftntid: #{ftntid}"
  puts "xftnarea: #{ftnarea}" 
  puts "xftnflags: #{ftnflags}" 
  puts "xftnmsgid: #{ftnmsgid}" 
  puts "xftnreply: #{ftnreply}"
  puts "control: #{control}"	
  puts "lines: #{lines}"
  puts "bytes: #{bytes}"
  puts "xref: #{xref}"
  puts "xcommentto: #{xcommentto}"
  puts "contenttype: #{contenttype}"
  puts "contenttransferencoding: #{contenttransferencoding}"
  puts "xgateway: #{xgateway}"
  puts "nntppostinghost: #{nntppostinghost}"
  puts "xcomplaintsto: #{xcomplaintsto}"
  puts "xtrace: #{xtrace}"
  puts "nntppostingdate: #{nntppostingdate}"
  puts "xoriginalbytes: #{xoriginalbytes}"
  puts "charset: #{charset}"  
  puts "xcomplaints: #{xcomplaints}"  

  puts "--- message ---"
  msgbody.each {|line| puts line}
  
  msg_text = msgbody.join("\n")
  
  add_nntp_msg(to,from,datetime,subject,msg_text,area.number, apparentlyto,
                 xcommentto, newsgroups, path, organization, replyto,
                 inreplyto, lines, bytes, xref, messageto, references, xgateway,
                 control, charset, contenttype, contenttransferencoding,
                 nntppostinghost, xcomplaintsto, xtrace, nntppostingdate,
                 xoriginalbytes, ftnarea, ftnflags, ftnmsgid, ftnreply,
		 ftntid, ftnpid)
end

def makenntpimportlist(group)
 list =nntp_list(group.grp)
 puts "-NNTP: The following areas have import mappings..."
 list.each {|x| puts "     #{x.nntp_net}      #{x.name}" }
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
         result,total,first,last = nntp_setgroup(area.nntp_net)
	 if result then
	   puts "-NNTP: total articles #{total}"
           puts "-NNTP: first article #{first}"
           puts "-NNTP: last article #{last}"
	   puts "-NNTP: area pointer #{area.nntp_pointer}"
	   pointer = set_pointer(area.nntp_pointer,first,last,total)
	   for i in pointer..last
	     article = nntp_getarticle(i)
	     if !article.nil? then
	       nntp_parsearticle(article,area) 
	     end
	   end
         else
	  puts "-ERROR: Group not found." #add loging
	 end
	}
     else
       puts "-ERROR: NNTP logon Failure"  #add logging
     end
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





#article = nntp_getarticle(first)

#nntp_parsearticle(article)
nntp_down

