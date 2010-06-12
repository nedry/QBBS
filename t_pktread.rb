##############################################
#											
#   t_pktread.rb --Incomming Packet Processor for Fidomail tosser for QBBS.		                                
#   (C) Copyright 2004, Fly-By-Night Software (Ruby Version)                        
#                                                                                                            
############################################## 

include Logger
require "pg_ext"
require "consts.rb"
require "t_class.rb"
require "t_const.rb"
require "db/db_area"
require "db/db_message"
require "db"

def nul_delimited(buffer,pointer,max) #reads in a field delimited by nulls with a maximum length

  result = ""
  max.times {
    pointer += 1
    char = buffer[pointer]
    if  char == 0 then 
      return [result,pointer]
    else
      result << char    
    end 
  }
  return [result,pointer]
end


def kludge_search(buffer)	#searches the message buffer for kludge lines and returns them

  area 	= nil
  msgid	= nil
  path		= nil
  tzutc	= nil
  charset	= nil
  tid		= nil
  pid		= nil
  intl		= nil
  topt		= nil
  fmpt		= nil
  reply 	= nil
  origin	= nil

  msg_array = buffer.split("\r")  #split the message into an array so we can deal with it.
  puts "kludge array:"
  match = (/^(AREA:)(.*)/) =~ msg_array[0] # detect the area, if there is one.
  if !match.nil? then 
    area = $2
    msg_array.delete_at(0) # We found it, so delete it from the message.
  else 
    puts "No Area: Netmail Message"
    area = NETMAIL   #we need to check that the message is really for us?  add this?
  end
  msg_array.each {|x|  match = (/(^\s\*\sOrigin:)(.+)(\(.+\))/) =~ x
    puts x
    if !match.nil? then
      origin = $3.gsub("(","")
      origin.gsub!(")","")
    end }
    msg_array.each_with_index {|x,i|
      if x.slice(0) == 1 then
        x.slice!(0)
        match = (/^(\S*)(.*)/) =~ x
        #puts "$1:#{$1} $2:#{$2}"
        if !match.nil? then 
          case $1
          when "MSGID:"
            msgid = $2.strip
            msg_array[i] = nil
          when "PATH:"
            path = $2.strip
            msg_array[i] = nil
          when "TZUTC:"
            tzutc = $2.strip
            msg_array[i] = nil
          when "CHARSET:"
            charset = $2.strip
            msg_array[i] = nil
          when "TID:"
            tid = $2.strip
            msg_array[i] = nil
          when "PID:"
            pid = $2.strip
            msg_array[i] = nil
          when "INTL"
            intl = $2.strip
            msg_array[i] = nil
          when "TOPT"
            topt = $2.strip
            msg_array[i] = nil
          when "FMPT"
            fmpt = $2.strip
            msg_array[i] = nil
          when "REPLY:"
            reply = $2.strip
            msg_array[i] = nil

          end
        end
      end }


      msg_array.compact!	#Delete every line we marked with a nil, cause it had a kludge we caught!
      puts
      puts "----"
      kludges = Kludge.new(area,msgid,path,tzutc,charset,tid,pid,intl,topt,fmpt,reply,origin)
      return [msg_array,kludges]

end

def read_a_message(path,offset)

  if File.exists?(path) then
    happy = File.open(path,"rb")
  else 
    puts "File Missing!"
    return PACKET_NOT_FOUND
  end
  happy.read(offset) #move the record pointer to the next record

  buffer	= happy.read(0xb2) # read the maximum possible header, although this may not all be used.
  orgnode	= (buffer[0x03] << 8) + buffer[0x02]
  destnode	= (buffer[0x05] << 8) + buffer[0x04]
  orgnet	= (buffer[0x07] << 8) + buffer[0x06]
  destnet	= (buffer[0x09] << 8) + buffer[0x08]
  attribute	= (buffer[0x0b] << 8) + buffer[0x0a]
  cost		= (buffer[0x0d] << 8) + buffer[0x0c]

  datetime = ""
  for i in 0..19 do 
    datetime << buffer[0x0e + i]
  end

  pointer = 0x21
  to,pointer = nul_delimited(buffer,pointer,36)
  from,pointer = nul_delimited(buffer,pointer,36)
  subject,pointer = nul_delimited(buffer,pointer,72)
  #puts "offset: #{offset.to_s(16)}"
  #puts "pointer: #{pointer.to_s(16)}"

  r_loc = offset + pointer + 1	#start of the message text will be a total of the offset and where we stopped
  #reading the header, which varies in size.  
  message = ""
  # puts "r_loc: #{r_loc.to_s(16)}"
  happy.rewind			#rewind to the beginning of the file
  happy.read(r_loc)		#move the file pointer to the end of the header,

  while true
    char = happy.read(1)			#read a character at a time
    if char[0] == 0 or char.nil? then 	#if the character is a null (end of message marker) or nil, then stop
      break
    else
      message << char 				#add the character 
    end
  end


  msg_array, kludges = kludge_search(message)

  fidomessage = A_fidonet_message.new(orgnode,destnode,orgnet,destnet,attribute,cost,
                                      datetime,to,from,subject,msg_array,kludges.area,
                                      kludges.msgid,kludges.path,kludges.tzutc,kludges.charset,
                                      kludges.tid,kludges.pid,kludges.intl,kludges.topt,kludges.fmpt,
                                      kludges.reply,kludges.origin)

  puts "Org:       #{fidomessage.orgnet}/#{fidomessage.orgnode}"
  puts "Dest:      #{fidomessage.destnet}/#{fidomessage.destnode}"
  puts "Attribute: #{fidomessage.attribute}"
  puts "Cost:      #{fidomessage.cost}"
  puts "Date Time: #{fidomessage.datetime}"
  puts "To:        #{fidomessage.to}"
  puts "From:      #{fidomessage.from}"
  puts "Subject:   #{fidomessage.subject}"
  puts "Area:      #{fidomessage.area}" if !fidomessage.area.nil?
  puts "Msgid:     #{fidomessage.msgid}" if !fidomessage.msgid.nil?
  puts "Path:      #{fidomessage.path}" if !fidomessage.path.nil?
  puts "TzUTZ:     #{fidomessage.tzutc}" if !fidomessage.tzutc.nil?
  puts "CharSet:   #{fidomessage.charset}" if !fidomessage.charset.nil?
  puts "Tosser ID: #{fidomessage.tid}" if !fidomessage.tid.nil?
  puts "Proc ID:   #{fidomessage.pid}" if !fidomessage.pid.nil?
  puts "Intl:      #{fidomessage.intl}" if !fidomessage.intl.nil?
  puts "Topt:      #{fidomessage.topt}" if !fidomessage.topt.nil?
  puts "Fmpt:      #{fidomessage.fmpt}" if !fidomessage.fmpt.nil?
  puts "Reply:     #{fidomessage.reply}" if !fidomessage.reply.nil?
  puts "Origin:    #{fidomessage.origin}" if !fidomessage.origin.nil?
  puts
  #fidomessage.message.each {|x| puts x}
  r_loc = happy.pos 		#this is the next offset.
  test = happy.read(5)		#lets read a head and see if we hit eof.  beyond eof, you read nil
  if test.nil? then isnext = false else
    isnext = !test[4].nil?		#if nil, we are done with the file.  
  end
  happy.close
  return [isnext,r_loc,fidomessage]
end





def read_pkt_header(path)

  if File.exists?(path) then
    happy = File.open(path,"rb")
  else
    return PACKET_NOT_FOUND
  end


  buffer   = happy.read(0x3a)

  if ((buffer[0x12] + (buffer[0x13] << 8)) != 2) then
    puts("Not a type 2 packet {#path}")
    return INVALID_PACKET;
  end

  orgnode	= (buffer[0x01] << 8) + buffer[0x00]
  destnode  	= (buffer[0x03] << 8) + buffer[0x02]
  orgnet	= (buffer[0x15] << 8) + buffer[0x14]
  destnet	= (buffer[0x17] << 8) + buffer[0x16]
  orgzone	= (buffer[0x23] << 8) + buffer[0x22]
  destzone	= (buffer[0x25] << 8) + buffer[0x24]

  year		= (buffer[0x05] << 8) + buffer[0x04]
  month		= (buffer[0x07] << 8) + buffer[0x06] + 1
  day		= (buffer[0x09] << 8) + buffer[0x08]
  hour		= (buffer[0x0b] << 8) + buffer[0x0a]
  min		= (buffer[0x0d] << 8) + buffer[0x0c]
  sec		= (buffer[0x0f] << 8) + buffer[0x0e]

  prodx   	=  buffer[0x18]
  major		=  buffer[0x19]

  capword 	= (buffer[0x2d] << 8) + buffer[0x2c]

  capword = 0 if (capword != ((buffer[0x28] << 8) + buffer[0x29]))

  if (capword & 0x0001) then       # FSC-0039 packet type 2+
    puts "Type 2+ Packet"
    prodx		= prodx + (buffer[0x2a] << 8)
    minor		= buffer[0x2b]
    orgzone		= buffer[0x2e] + (buffer[0x2f] << 8)
    destzone		= buffer[0x30] + (buffer[0x31] << 8)
    orgpoint		= buffer[0x32] + (buffer[0x33] << 8)
    destpoint		= buffer[0x34] + (buffer[0x35] << 8)
  end

  pktpwd = ""
  for i in 0..7 do 
    pktpwd << buffer[0x1a + i]
  end
  # pktpwd[8]='\0'

  #puts "Orig:    #{orgzone}:#{orgnet}/#{orgnode}"
  #puts "Dest:    #{destzone}:#{destnet}/#{destnode}"
  #puts "product: #{prodx.to_s(16)}"
  #puts "rev:     #{major}.#{minor}"
  #puts "pwd:     #{pktpwd.to_s}"
  #puts
  happy.close
  return SUCCESS
end



def setitup
  user = fetch_user(get_uid(FIDOUSER))
  for i in 0..a_total do
    user.lastread[i] = 0 if user.lastread[i] == nil 
  end
  update_user(user,get_uid(FIDOUSER))
end

def f_local(user)
  if !user_exists(user) then 
    puts "not found"
    return false
  else 
    puts "found"
    return true
  end
end

def add_fido_msg(fidomessage)

  if fidomessage.area == NETMAIL then
    if f_local(fidomessage.to) then 
      area = fetch_area(0)
      table = area.tbl
      number = 0
    else
      table,number = find_fido_area(BADNETMAIL)
      puts "-FIDO: Bad netmail detected."
      #generate a bounce message
    end
  else
    table,number = find_fido_area(fidomessage.area)
  end
  msg_text = fidomessage.message.join(DLIM)
  msg_date = fidomessage.datetime.strip
  m_to = fidomessage.to
  m_from = fidomessage.from
  subject = fidomessage.subject
  orgnode = fidomessage.orgnode
  destnode = fidomessage.destnode
  orgnet = fidomessage.orgnet
  destnet = fidomessage.destnet
  attribute = fidomessage.attribute
  cost = fidomessage.cost
  area = fidomessage.area
  msgid = fidomessage.msgid
  path = fidomessage.path
  tzutc = fidomessage.tzutc
  charset = fidomessage.charset
  tid = fidomessage.tid
  pid = fidomessage.pid
  topt = -1
  topt = fidomessage.topt if !fidomessage.topt.nil?
  intl = fidomessage.intl
  fmpt = -1
  fmpt = fidomessage.fmpt if !fidomessage.fmpt.nil?
  origin = fidomessage.origin

  f_network = true
  exported = true
  network = false
  reply = false

  if !table.nil? then 
    msg_text.gsub!("'",BEL) if msg_text != nil
    if pid != nil
      pid.gsub!("'",BEL)
      pid = pid[0..79] if pid.length > 80
    end

    if msgid != nil
      msgid.gsub!("'",BEL)
      msgid = msgid[0..79] if msgid.length > 80
    end

    tid.gsub!("'",BEL) if tid != nil

    if m_to != nil then
      m_to.gsub!("'",BEL) 
      m_to.upcase!
    end
    m_from.gsub!("'",BEL) if m_from != nil
    subject.gsub!("'",BEL) if subject != nil
    puts "----"
    puts "FIDO: importing message to: #{table}"
    # puts "INSERT INTO #{table} (m_to, m_from, \ 
    #          msg_date, subject, msg_text, exported,network,f_network,orgnode,destnode,\
    #	   orgnet,destnet,attribute,cost,area,msgid,path,tzutc,charset,\
    #	   tid,pid,intl,topt,fmpt,origin,reply) VALUES \ 
    #          ('#{m_to}', '#{m_from}', '#{msg_date}', '#{subject}',\
    #	  '#{msg_text}', '#{exported}','#{network}', '#{f_network}','#{orgnode}',\
    #	  '#{destnode}','#{orgnet}', '#{destnet}','#{attribute}',\
    #	  '#{cost}','#{area}','#{msgid}','#{path}','#{tzutc}',\
    #	  '#{charset}','#{tid}','#{pid}','#{intl}','#{topt}',\
    #	  '#{fmpt}','#{origin}','#{reply}')"

    @db.exec("INSERT INTO #{table} (m_to, m_from, \ 
           msg_date, subject, msg_text, exported,network,f_network,orgnode,destnode,\
     orgnet,destnet,attribute,cost,area,msgid,path,tzutc,charset,\
     tid,pid,intl,topt,fmpt,origin,reply) VALUES \ 
          ('#{m_to}', '#{m_from}', '#{msg_date}', '#{subject}',\
    '#{msg_text}', '#{exported}','#{network}', '#{f_network}','#{orgnode}',\
             '#{destnode}','#{orgnet}', '#{destnet}','#{attribute}',\
             '#{cost}','#{area}','#{msgid}','#{path}','#{tzutc}',\
             '#{charset}','#{tid}','#{pid}','#{intl}','#{topt}',\
             '#{fmpt}','#{origin}','#{reply}')") 

             #Update pointers
             user = fetch_user(get_uid(FIDOUSER))

             #on first run with database... the user might not have logged in...
             user.lastread = [] if user.lastread == nil

             user.posted = user.posted + 1
             user.lastread[number] = high_absolute(table)
             update_user(user,get_uid(FIDOUSER))
             return 
  else
    puts "Error: No mapping found for #{fidomessage.area}.  Not Importing"
  end
end

def process_packet(path) 		#this is a shell for what will be the inbound packet routine.

  condition = read_pkt_header(path)
  ok = false
  total = 0
  ddate = Time.now.strftime("%m/%d/%Y at %I:%M%p") 
  case condition
  when PACKET_NOT_FOUND
    add_log_entry(8,Time.now,"Fido Import Error: No Packet Found.")
    puts "!No Packet Found"
    #Log Stuff
  when PACKET_IO_ERROR
    puts "!Bad Packet Detected"
    add_log_entry(8,Time.now,"Fido Import Error:Bad Packet Detected.")
    #Log Stuff
  when INVALID_PACKET
    puts "!Header Invalid or Not Type 2 or 2+"
    add_log_entry(8,Time.now,"Fido Import Error:Header Invalid or not Type 2 or 2+")
    #Log Stuff
  else
    ok = true
  end #Case condition
  if ok then
    add_log_entry(2,Time.now,"Starting Fido message import")
    isnext,offset,fidomessage = read_a_message(path,0x3a)     #the first message always has an offset of 0x3a
    add_fido_msg(fidomessage)
    total +=1
    while isnext
      #puts "isnext: #{isnext}"
      isnext,offset,fidomessage = read_a_message(path,offset)
      add_fido_msg(fidomessage)
      total +=1
      #process the message we got.  
    end
    add_log_entry(2,Time.now,"#{total} Fido messages imported")
    puts "-FIDO: Import Complete.  #{total} messages imported."
  end

end #process_packet



#setitup
#process_packet ("happy.pkt")
