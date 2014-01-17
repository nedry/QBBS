require 'models/message'
require 'models/area'
require 'dm-validations'
require 'consts.rb'
require 'encodings.rb'
require 'db/db_groups'
require 'models/qwkroute'

#require "iconv"

def scanforaccess(user)
  for i in 0..(a_total - 1) do
    area = fetch_area(i)
    pointer = get_pointer(user,i)
    if pointer.nil? then
      add_pointer(user,i,area.d_access,0)
    end
  end
end

def m_total(area)
  Message.all(:number => area).count
end

def system_m_total
  Message.all.count
end

def new_messages(area,ind)
  ind = 0 if ind.nil?
  Message.all(:absolute.gt => ind, :number => area).count
end

def absolute_message(area,ind)
  ind = 0 if ind.nil?
  lazy_list = Message.all(:number => area, :order => [ :absolute ])
  result = 0
  result = lazy_list[ind-1].absolute if !lazy_list[ind-1].nil?
end

def high_absolute(table)
  if m_total(table) > 0 then
    result = absolute_message(table,m_total(table))
  else result = 0 end
  return result
end

def delete_msg(ind)
  message = Message.first(:absolute => ind)
  message.destroy!
end

def delete_msgs(area,first,last)
  message = Message.all(:absolute.gte => first, :absolute.lte => last, :number => area)
  message.destroy!
end

def fido_export_messages(area,first)
  messages = Message.all(:absolute.gte => first,  :exported => false, :number => area)
end


def export_messages(area,first)
  messages = Message.all(:absolute.gte => first,  :exported => false, :number => area)
end

def find_fido_area(area)
  area = Area.first(:fido_net => area)
  number = area.number
  return number
end

def exported(absolute)
  message = Message.first(:absolute => absolute)
  message.exported = true
  message.save!
end

def update_msg(r)
  r.save
end

def fetch_msg(absolute)
  message = Message.first(:absolute => absolute)
end

def e_total(user)
  Message.all(:number => 0,  :conditions => ["m_to ILIKE ?", user] ).count
end

def msgid_exist(msgid)
  dude = Message.first(:msgid => msgid)
end


def new_email(ind,user)
  ind = 0 if ind.nil?
  Message.all(:number => 0, :absolute.gt => ind, :conditions => ["m_to ILIKE ?", user]).count
end


def email_absolute_message(ind,m_to)
  ind = 0 if ind.nil?
  lazy_list = Message.all(:number => 0, :conditions => ["m_to ILIKE ?", m_to], :order => [:absolute ])
  result = lazy_list[ind-1].absolute
end

#def add_nntp_msg(m_to,m_from,msg_date,subject,msg_text,number, apparentlyto,
#                 xcommentto, newsgroups, path, organization, replyto,
#                 inreplyto, lines, bytes, xref, messageto, references, xgateway,
#                 control, charset, contenttype, contenttransferencoding,
#                 nntppostinghost, xcomplaintsto, xtrace, nntppostingdate,
#                 xoriginalbytes, ftnarea, ftnflags, ftnmsgid, ftnreply,
#		  ftntid, ftnpid, messageid)


  
#  area = Area.first(:number => number)
#  message = area.messages.new(
#    :m_to => m_to,
#    :m_from => m_from,
#    :msg_date => msg_date,
#    :subject => subject,
#    :msg_text => msg_text, 
#    :exported => true,
#    :usenet_network => true,
#    :apparentlyto => apparentlyto,
#    :xcommentto => xcommentto,
#    :newsgroups => newsgroups,
#    :path => path,
#    :organization => organization,
#    :replyto => replyto,
#    :inreplyto => inreplyto,
#    :lines => lines,
#    :bytes => bytes,
#    :xref => xref,
#    :messageto => messageto,
		#added nntpreferences because you can't auto_update a field change.  
		#this is so we can send the reference line back to the nntp server for threading on 
		#newsreaders.  made it a text field because there can be *loads* of references.
		#:references => references,
#    :nntpreferences => references,
#    :xgateway => xgateway,
#    :control => control,
#    :charset => charset,
#    :contenttype  => contenttype,
#    :contenttransferencoding => contenttransferencoding,
#    :nntppostinghost => nntppostinghost,
#    :xcomplaintsto => xcomplaintsto,
#    :xtrace  => xtrace,
#    :nntppostingdate => nntppostingdate,
#    :xoriginalbytes => xoriginalbytes,
#    :fntarea => ftnarea,
#    :fntflags => ftnflags,
#    :msgid => ftnmsgid,
#    :tid  => ftntidtrue,  
#    :pid  => ftnpid,
#		:msgid => messageid
#  ) 
  
#  worked = message.save
#  if !worked then
#   message.errors.each{|x| puts x}
#  end
#  return high_absolute(area.number)
#end


def add_msg(m_to,m_from,number,options = {})
	
  #added nntpreferences because you can't auto_update a field change. 
  #this is so we can send the reference line back to the nntp server for threading on 
  #newsreaders.  made it a text field because there can be *loads* of references.

		
  default = { :msg_date => Time.now.strftime("%Y-%m-%d %I:%M%p"),
	       :subject => "No Subject",
	       :msg_text => "",
	       :exported => false,
	       
	       :network => false,
	       
	       :destnode => -1,
	       :destnet => -1,
	       :intl => nil,
	       :topt => -1,
	       
	       :smtp => false,
	       
	       :f_network => false,
	       
	       :orgnode => nil,
	       :orgnet => nil,
	       :attribute => nil,
	       :cost => nil,
	       :area => nil,
	       :msgid => nil,
	       :path => nil,
	       :tzutc => nil,
	       :charset => nil,
	       :tid => nil,
	       :pid => nil,
	       :fmpt => nil,
	       :origin => nil,
	       :reply => false,
	       :q_msgid => nil,
	       :q_tz => nil,
	       :q_via => nil,
	       :q_reply => nil,
	       :nntpreferences => nil,
	       
	       :usenet_network => false,
	       
               :apparentlyto => nil,
               :xcommentto => nil,
               :newsgroups => nil,
               :organization => nil,
               :replyto => nil,
               :inreplyto => nil,
               :lines => nil,
               :bytes => nil,
               :xref => nil,
               :messageto => nil,
               :nntpreferences => nil,
               :xgateway => nil,
	       :control => nil,
               :contenttype  => nil,
               :contenttransferencoding => nil,
	       :nntppostinghost => nil,
               :xcomplaintsto => nil,
               :xtrace  => nil,
               :nntppostingdate => nil,
               :xoriginalbytes => nil,
               :fntarea => nil,
               :fntflags => nil}
	       
  options = default.merge(options)

 
  area = Area.first(:number => number)
  message = area.messages.new(
    :m_to => m_to,
    :m_from => m_from,
    :msg_date => options[:msg_date],
    :subject => options[:subject],
    :msg_text => options[:msg_text], 
    :exported => options[:exported],
    :network => options[:network],
    :reply => options[:reply],
    :destnode => options[:destnode],
    :destnet => options[:destnet],
    :intl => options[:intl],
    :topt => options[:topt],
    :smtp => options[:smtp],
    :exported => options[:exported],
    :f_network  => options[:f_network],
    :orgnode  => options[:orgnode], 
    :orgnet  => options[:orgnet], 
    :attribute  => options[:attribute], 
    :cost  => options[:cost],
    :area  => options[:area],  
    :msgid  => options[:msgid], 
    :path  => options[:path], 
    :tzutc  => options[:tzutc],  
    :charset  => options[:charset],
    :tid  => options[:tid],  
    :pid  => options[:pid],
    :fmpt  => options[:fmpt],  
    :origin  => options[:origin],
    :q_msgid => options[:q_msgid],
    :q_tz => options[:q_tz],
    :q_via => options[:q_via],
    :q_reply => options[:q_reply],
    :nntpreferences => options[:nntpreferences],
    :usenet_network => options[:usenet_network],       
    :apparentlyto => options[:apparentlyto],
    :xcommentto => options[:xcommentto],
    :newsgroups => options[:organization],
    :organization => options[:organization],
    :replyto => options[:replyto],
    :inreplyto => options[:inreplyto],
    :lines => options[:lines],
    :bytes => options[:bytes],
    :xref => options[:xref],
    :messageto => options[:messageto],
    :nntpreferences => options[:nntpreferences],
    :xgateway => options[:xgateway],
    :control => options[:contenttype],
    :contenttype  => options[:contenttype],
    :contenttransferencoding => [:contenttransferencoding],
    :nntppostinghost => options[:nntppostinghost],
    :xcomplaintsto => options[:xcomplaintsto],
    :xtrace  => options[:xtrace],
    :nntppostingdate => options[:nntppostingdate],
    :xoriginalbytes => options[:xoriginalbytes],
    :fntarea => options[:fntarea],
    :fntflags => options[:fntflags]
  ) 
  
  worked = message.save
  if !worked then
   message.errors.each{|x| puts x}
  end
  return high_absolute(area.number)
end

def add_qwk_message(message, area,qwkuser)
  user = fetch_user(get_uid(qwkuser))
  pointer = get_pointer(user,area.number)
  to = message.to.upcase.strip
  m_from = message.from.upcase.strip  
  group =  fetch_group_grp(area.grp)
  qwknet = get_qwknet(group)
  dest,route = get_qwk_dest(q_via)
  qwkroute_scavenge(qwknet)
  
  if !route.nil?
   current = get_qwkroute(qwknet,dest)
   if !current.nil? then
     current.modified = Time.now
     update_qwkroute(current)
   else
   save_qwkroute(qwknet,dest,route)
 end
 end
  
  absolute = add_msg(to, m_from, area.number,
			:msg_date => message.date,
			:subject => message.subject.strip, 
			:msg_text => message.text, 
			:exported => true, 
			:network => true,
			:q_msgid => message.msgid, 
			:q_tz => message.tz ,
			:q_via => message.via, 
			:q_reply => message.reply)
			
  user.posted = user.posted + 1
  pointer.lastread = absolute
  update_pointer(pointer)
  update_user(user)
end

def nntp_convert(text)

        text_out = ""
	text_out = text.force_encoding('UTF-8').encode('UTF-16', :invalid => :replace, :replace => '?').encode('UTF-8') if !text.nil?

	return text_out
end
  
	
def convert_to_utf8(message, unixterm=false)
  # this makes messages display properly on a unix terminal
  if unixterm
    temp = message.gsub(227.chr,"\n") #replace qwk delimilter with crlf
    return temp.force_encoding("ibm437").encode("utf-8")
  end

  # this works with syncterm
  temp = message.gsub(227.chr,"\r") #replace qwk delimilter with cr
# this works with syncterm
  temp = message.gsub(227.chr,"\r") #replace qwk delimilter with cr
  temp2 = ""
  temp2.force_encoding("UTF-8")
  temp.each_char do |c|
    if c.ord <= 127 then
      temp2 << c
    else

       temp2 << Encodings::ASCII_UNICODE[c]

    end
  end
  return temp2
end

def convert_to_ascii(message)
  temp = ""
  temp.force_encoding("ASCII-8BIT")

  message.each_char do |c|
    if c.ord <= 127 then
      temp << c 
    else
      
      if c.ord <= 254 
				begin
          temp << Encodings::UNICODE_ASCII[c] 
				rescue
				  puts "-NNTP: Encoding failed for chararcter: #{c}"
					temp << " "
				end
      end
    end
  end
  return temp
end

def qwk_route(route)
  out_area=find_qwk_single_hop(route)
  puts "hub: #{out_area.name}" if !out_area.nil?
  if out_area.nil? then     #the message is not to a hub
    out_area = find_qwk_route(route) #is the message to a node we know about?
  #  puts "route: #{out_area.name}" if !out_area.nil?
  end
  return out_area
end

  def get_orig_address(msgid)
    orig = nil
    if !msgid.nil? then
     match = (/^(\S*)(\S*)/) =~ msgid.strip
     orig = $1 if !match.nil?
    end
    return orig
  end
  
  def qwkmailadr(address)

  to = nil;route = nil
  if !address.index(".") then
    happy = (/^(.+)@([a-z,A-Z,0-9]+)/) =~ address
    if happy then
      to = $1;route = $2
    end
  end
  return [to,route]
end

def stmpmailadr(address)
  happy = (/^(.+)@(.+)\.(.+)/) =~ address
  if happy then return true else return false end
end

def netmailadr(address)

  to = nil;zone = nil;net = nil;node = nil;point = nil
  happy = (/^(.*)@(\d?):(\d{1,4})\/(.*)/) =~ address
  if happy then
    to = $1;zone = $2;net = $3;node = $4
    grumpy = (/(\d{1,4})\.(\d{1,4})/) =~ node
    if grumpy then
      node = $1;point = $2
    end
  zone = zone.to_i
  net = net.to_i
  node = node.to_i
  point = point.to_i
  end
  return [to,zone,net,node,point]
end

def parse_intl(address)

  happy = (/^(\d?):(\d{1,4})\/(.*)/) =~ address
  if happy then
    zone = $1;net = $2;node = $3
    grumpy = (/(\d{1,4})\.(\d{1,4})/) =~ node
    if grumpy then
      node = $1;point = $2
    end
  end
  return [zone,net,node,point]
end
