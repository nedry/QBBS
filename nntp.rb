##############################################
#											
#   nntp.rb --NNTP connector for QBBS.		                                
#   (C) Copyright 2012, Fly-By-Night Software (Ruby Version)                        
#                                                                                                            
##############################################

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

NNTP_HOST = "news-europe.giganews.com"
NNTP_PORT = "119"


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
    return [success,params[1],params[2],params[3]]
  end
end

def nntp_getarticle(artnum)

 article = []
 done = false
 nntp_send("ARTICLE #{artnum}")
 while !done 
   line = nntp_recv
   article << line
   done = true if line == "."
 end
 return article
end

def nntp_parsearticle(article)
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
        lines = $2
      when "Bytes"
	bytes = $2
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
  
  nntpmessage = A_nntp_message.new(apparentlyto, to, xcommentto,newsgroups,path,
		 from,organization,replyto,inreplyto,datetime,subject,
		 lines,bytes,xref,messageto,references,xgateway,control,charset,
		 contenttype, contenttransferencoding,  
		 nntppostinghost, xcomplaints, xtrace, nntppostingdate, xoriginalbytes,
		 ftnarea,ftnflags,ftnmsgid, ftnpid, ftntid, ftnreply,msgbody)
  return nntpmessage
end



open_nntp(NNTP_HOST, NNTP_PORT)
if nntp_login("dennisnedry","flatmo1") then
  puts "-NNTP: Succesful Login"
else
  puts "-NNTP: Authentication Failure"
end

result,total,first,last = nntp_setgroup("alt.bbs.synchronet")

puts "-NNTP: total articles #{total}"
puts "-NNTP: first article #{first}"
puts "-NNTP: last article #{last}"

article = nntp_getarticle(first)

puts article.length
#article.each {|line| puts line}
nntp_parsearticle(article)

