#############################################
#											
#   t_pktwrite.rb --Outgoing Packet Processor for Fidomail tosser for QBBS.		                                
#   (C) Copyright 2004, Fly-By-Night Software (Ruby Version)                        
#                                                                                                            
############################################## 

include Logger
#require "postgres"
require "tools.rb"
require "consts.rb"
require "t_class.rb"
require "t_const.rb"
require "db_class.rb"
require "db_area"
require "db_message"
require "db"


 def write_pkt_header(f_hdr)
 
   buffer = ''
   buffer << (f_hdr.orgnode & 0x00ff)
   buffer << ((f_hdr.orgnode & 0xff00) >> 8)
   buffer <<  (f_hdr.destnode & 0x00ff)
   buffer << ((f_hdr.destnode & 0xff00) >> 8)
   buffer << (f_hdr.year & 0x00ff)
   buffer << ((f_hdr.year & 0xff00) >> 8)
 
   buffer << f_hdr.month - 1 << 0
   
   buffer << f_hdr.day << 0

   buffer << f_hdr.hour << 0
   
   buffer << f_hdr.min << 0

   buffer << f_hdr.sec << 0
   
   buffer << 0 << 0 << 2 << 0

   buffer << (f_hdr.orgnet & 0x00ff)
   buffer << ((f_hdr.orgnet & 0xff00) >> 8)
   
   buffer << (f_hdr.destnet & 0x00ff)
   buffer << ((f_hdr.destnet & 0xff00) >> 8)
   
   buffer << 255
   
   buffer << 1
   total = 8
   password = f_hdr.password
   password = password[0..7] if password.length > 8 
   nuls = total - password.length
   buffer <<  password.strip
   nuls.times {buffer << 0}
   
   buffer << ((f_hdr.orgzone & 0x00ff))
   buffer << ((f_hdr.orgzone & 0xff00) >> 8)

   buffer << ((f_hdr.destzone & 0x00ff))
   buffer << ((f_hdr.destzone & 0xff00) >> 8)
   buffer << 0 << 0 << 0 
   buffer << 1
   buffer << 0 << 0
   buffer << 1  << 0
  
   buffer << ((f_hdr.orgzone & 0x00ff))
   buffer << ((f_hdr.orgzone & 0xff00) >> 8)
  
   buffer << ((f_hdr.destzone & 0x00ff))
   buffer << ((f_hdr.destzone & 0xff00) >> 8)
 
   buffer << (f_hdr.orgpoint & 0x00ff)
   buffer << ((f_hdr.orgpoint & 0xff00) >> 8)
  
   buffer << (f_hdr.destpoint & 0x00ff)
   buffer << ((f_hdr.destpoint & 0xff00) >> 8)
   buffer << 0 << 0 << 0 << 0
  
  @happy.write buffer
 end
 
 def time_to_fido(bbs_date_time)  #Convert native BBS time/date into FidoNet time/date
 
  month_arr =  ['Jan','Feb','Mar','Apr','May','Jun',
            'Jul','Aug','Sep','Oct','Nov','Dec']

  match = (/^(\S*)\s(.*)/) =~ bbs_date_time
  bbs_date = $1;bbs_time = $2
  match = (/^(\S\S)(\S\S)-(\S*)-(\S*)/) =~ bbs_date_time
  year = $2; mon = $3;day = $4
  fido_time = "#{day} #{month_arr[mon.to_i - 1]} #{year}  #{bbs_time}"
  return fido_time
 end
 
 def write_nul_delimited(buffer,output,max)
   output = output[0..max - 1] if output.length > max 
    buffer <<  output << 0
   return buffer
 end
 
 def add_kludge_lines(buffer,message)
 
 
  if !message.area.nil? and message.area != NETMAIL then 
   buffer << "AREA:" << message.area << CR.chr
  end
  if !message.msgid.nil? then
   buffer << 1 << "MSGID: " <<message.msgid << CR.chr
  end
  if !message.tzutc.nil? then
   buffer << 1 << "TZUTC: " <<message.tzutc << CR.chr
  end
  if !message.charset.nil? then
   buffer << 1 << "CHARSET: " << message.charset << CR.chr
  end
  if !message.tid.nil? then
   buffer << 1 << "TID: " << message.tid << CR.chr
  end
  if !message.fmpt.nil? then
   buffer << 1 << "FMPT " << message.fmpt.to_s << CR.chr
  end
  if !message.reply.nil? then 
   buffer << 1 << "REPLY: " << message.reply << CR.chr
  end
  if !message.topt.nil? then
   buffer << 1 << "TOPT " << message.topt.to_s << CR.chr
  end
  if !message.intl.nil? then
   buffer << 1 << "INTL " << message.intl << CR.chr
  end
  return buffer
 end
 
 def write_pkt_end
  buffer = ''
  buffer << 0 << 0
  @happy.write buffer
 end
 
 def write_a_message(message)
 

  buffer =''
  buffer << 2 << 0
  buffer << (message.orgnode & 0x00ff)
  buffer << ((message.orgnode & 0xff00) >> 8)
  #buffer << 0
  buffer << (message.destnode & 0x00ff)
  buffer << ((message.destnode & 0xff00) >> 8)
  
  buffer << (message.orgnet & 0x00ff)
  buffer << ((message.orgnet & 0xff00) >> 8)

  buffer << (message.destnet & 0x00ff)
  buffer << ((message.destnet & 0xff00) >> 8)
  
  buffer << (message.attribute & 0x00ff)
  buffer << ((message.attribute & 0xff00) >> 8)
  
  buffer << (message.cost & 0x00ff)
  buffer << ((message.cost & 0xff00) >> 8)
 
  datetime = time_to_fido(message.msg_date)
  buffer << datetime.fit(19)
  buffer << 0
  buffer = write_nul_delimited(buffer,message.m_to,35)
  buffer = write_nul_delimited(buffer,message.m_from,35)
  buffer = write_nul_delimited(buffer,message.subject,35)
  message.msg_text.gsub!(DLIM,CR.chr)
  buffer = add_kludge_lines(buffer,message)
  buffer << message.msg_text << CR.chr

  if message.area != NETMAIL then
   buffer << TEAR << CR.chr
   buffer << ORGIN << CR.chr
  end
  buffer << 0
  @happy.write buffer
 end
 
 def create_pkt_header
 header_date = Time.now
 orgnode = FIDONODE
 destnode = H_FIDONODE
 year = header_date.year
 month = header_date.month
 day = header_date.day
 hour = header_date.hour
 min = header_date.min
 sec = header_date.sec
 pkttype = nil
 orgnet = FIDONET
 destnet = H_FIDONET
 prodcode = nil
 sernum = nil
 password = H_PKT_PASSWORD
 orgzone = FIDOZONE
 destzone = H_FIDOZONE
 auxnet = nil
 cwcopy = nil
 revision = nil
 cword = nil
 orgpoint = FIDOPOINT
 destpoint = 0
 
 f_hdr = Packet_header_two.new(orgnode,destnode,year,month,day,hour,min,sec,pkttype,
		     orgnet,destnet,prodcode,sernum,password,orgzone,
		     destzone,auxnet,cwcopy,revision,cword,orgpoint,
		     destpoint)
		     
 write_pkt_header(f_hdr)
 end
 
 def convert_a_message(table,f_area,msg)
 
 system = fetch_system
 #puts "system.f_msgid: #{system.f_msgid}"
 system.f_msgid  +=1
# puts "system.f_msgid + 1: #{system.f_msgid}"
 n_msgid = system.f_msgid.to_s(16)
 #puts "n_msgid: #{n_msgid}"
 update_system(system)
 
 delete = false
 locked = false
 number = 0
 m_to = msg.m_to
 m_from = msg.m_from
 msg_date = msg.msg_date
 subject = msg.subject
 msg_text = msg.msg_text
 
 exported = false
 network = false
 f_network = true
 orgnode = FIDONODE
 destnode = H_FIDONODE
 destnode = msg.destnode if !msg.destnode.nil?
 orgnet = FIDONET
 destnet = H_FIDONET
 destnet = msg.destnet if !msg.destnet.nil?
 attribute = 0
 cost = 0
 area = f_area
 msgid = "#{FIDOZONE}:#{FIDONET}/#{FIDONODE}.#{FIDOPOINT} #{n_msgid}"
 path = nil
 tzutc = TZONE
 charset = CHARSET
 tid = TID
 pid = nil
 intl = nil
 intl = msg.intl if !msg.intl.nil?
 topt = TOPT
 topt = msg.topt if !msg.topt.nil? and topt != -1
 fmpt = FMPT
 #puts "f_network: #{msg.f_network}"
 reply = nil
 reply = msg.msgid if f_network 
 origin = nil
 smtp = false
  
  message = DB_message.new(delete,locked,number,m_to,m_from,msg_date,subject,msg_text,exported,network,f_network,
		orgnode,destnode,orgnet,destnet,attribute,cost,area,msgid,
		path, tzutc,charset,tid,pid,intl,topt,fmpt,reply,origin,smtp)

 write_a_message(message)
 end
 
 def open_pkt(path)
   begin
 @happy = File.new("#{path}", File::CREAT|File::RDWR, 0644)
  rescue
   puts "Error writing file."
   return PACKET_CREATE_ERROR
  end
 end
 
 def fido_export_lst

  result = []
  res = @db.exec("SELECT number,tbl FROM areas WHERE fido_net <> '' \
  and fido_net <> '#{BADNETMAIL}' ORDER BY number ")
 
 temp = result_as_array(res)

 for i in 0..temp.length - 1 do
  result << F_export.new(temp[i][0].to_i,temp[i][1])
 end
  return result
 end



 def pkt_export_run
  user = fetch_user(get_uid(FIDOUSER))
  puts user.name
  #clearoldrep
  puts "-FIDO: Starting export."
  #open_database
  add_log_entry(2,Time.now,"Starting Fido message export.")
  packet_filename = "#{Time.now.to_i.to_s(16)}.pkt"
  open_pkt("#{TEMPOUTDIR}/#{packet_filename}")
  create_pkt_header
  xport = fido_export_lst
  #rewritereplog
  total = 0
  xport.each {|xp|
  area = fetch_area(xp.num)
  puts "-FIDO: Now Processing #{area.name} area."
  
   #on first run with database... the user might not have logged in...
  user.lastread = [] if user.lastread == nil
  
  pointer = user.lastread[xp.num] || 0
  #puts "-FIDO: Last [absolute] Exported Message...#{pointer}"
  #puts "-FIDO: Highest [absolute] Message.........#{high_absolute(area.tbl)}"
  #puts "-FIDO: Total Messages.....................#{m_total(area.tbl)}"
  new = new_messages(area.tbl,pointer)
  puts "-FIDO: Messages to Export.................#{new}"
  puts 

  if new > 0 then

    for i in pointer.succ..high_absolute(area.tbl) do
     workingmessage = fetch_msg(area.tbl,i)
     if !workingmessage.nil? then 
      if  !workingmessage.f_network and !workingmessage.exported then
       convert_a_message(area.tbl,area.fido_net,workingmessage)
       total += 1
       exported(area.tbl,workingmessage.number)
      else
       error = workingmessage.network ?
	"Message has already been imported.":
	"Message [#{i}] doesn't exist."
	m = "Message #{i} not exported.  #{error}"
	#replogandputs "-#{m}"
	
      end
     end
     puts "-FIDO: Updating message pointer for board #{xp.table}"
     n = xp.num
     user.lastread[n] = high_absolute(area.tbl)
     update_user(user,get_uid(FIDOUSER))
    end
   end
	}
    write_pkt_end
    @happy.close
    
   
    if total == 0
     system("rm #{TEMPOUTDIR}/#{packet_filename}") 
     puts "-FIDO: No messages to export.  Deleting Packet."
     add_log_entry(2,Time.now,"No messages to export.  Deleting Packet #{packet_filename}.")
    else
     puts "-FIDO: Export Complete, #{total} messaged exported."
     add_log_entry(2,Time.now,"Export Complete #{total} message(s) exported.")

     bundle
    end

    return total
   end


