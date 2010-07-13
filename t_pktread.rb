##############################################
#											
#   t_pktread.rb --Incomming Packet Processor for Fidomail tosser for QBBS.		                                
#   (C) Copyright 2004, Fly-By-Night Software (Ruby Version)                        
#                                                                                                            
############################################## 

include Logger
require "consts.rb"
require "t_class.rb"
require "t_const.rb"
require "db/db_area"
require "db/db_message"

def nul_delimited(buffer,pointer,max) #reads in a field delimited by nulls with a maximum length

  result = ""
  max.times {
    pointer += 1
    char = buffer[pointer]
    if  char.ord == 0 then 
      return [result,pointer]
    else
      result << char    
    end 
  }
  return [result,pointer]
end


def kludge_search(buffer)	#searches the message buffer for kludge lines and returns them
  kludge = Kludge.new

  msg_array = buffer.split("\r")  #split the message into an array so we can deal with it.

  match = (/^(AREA:)(.*)/) =~ msg_array[0] # detect the area, if there is one.

  if match then
    kludge.area = $2
    msg_array.delete_at(0) # We found it, so delete it from the message.
  else
    puts "No Area: Netmail Message"
    kludge.area = NETMAIL  # We need to check that the message is really for us?  add this?
  end

  msg_array.each {|x|
    match = (/(^\s\*\sOrigin:)(.+)(\(.+\))/) =~ x
    puts x
    if match then
      kludge.origin = $3.gsub(/[()]/,"")
    end
  }

  # if we find any of these, reject the message
  invalid = [
    "MSGID:", "PATH:", "TZUTC:", "CHARSET:", "TID:",
    "PID", "INTL", "TOPT", "FMPT", "REPLY:"
  ]

  valid_messages = []
  msg_array.each do |x|
    match = (/^(\S*)(.*)/) =~ x
    if match then
      header = $1.slice!(0)
      value = $2
      if invalid.include? header
        field = header.gsub(/:/, '')
        kludge[field] = value
      else
        valid_messages << x
      end
    end
  end

  puts
  puts "----"
  return [valid_messages, kludge]
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
  orgnode	= (buffer[0x03].ord << 8) + buffer[0x02].ord
  destnode	= (buffer[0x05].ord << 8) + buffer[0x04].ord
  orgnet	= (buffer[0x07].ord << 8) + buffer[0x06].ord
  destnet	= (buffer[0x09].ord << 8) + buffer[0x08].ord
  attribute	= (buffer[0x0b].ord << 8) + buffer[0x0a].ord
  cost		= (buffer[0x0d].ord << 8) + buffer[0x0c].ord

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
    if char.ord == 0 or char.nil? then 	#if the character is a null (end of message marker) or nil, then stop
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
 
  puts "buffer: #{buffer}"

  if ((buffer[0x12].ord + (buffer[0x13].ord << 8)) != 2) then
    puts("Not a type 2 packet #{path}")
    return INVALID_PACKET;
  end

  orgnode	= (buffer[0x01].ord << 8) + buffer[0x00].ord
  destnode  	= (buffer[0x03].ord << 8) + buffer[0x02].ord
  orgnet	= (buffer[0x15].ord << 8) + buffer[0x14].ord
  destnet	= (buffer[0x17].ord << 8) + buffer[0x16].ord
  orgzone	= (buffer[0x23].ord << 8) + buffer[0x22].ord
  destzone	= (buffer[0x25].ord << 8) + buffer[0x24].ord

  year		= (buffer[0x05].ord << 8) + buffer[0x04].ord
  month		= (buffer[0x07].ord << 8) + buffer[0x06].ord + 1
  day		= (buffer[0x09].ord << 8) + buffer[0x08].ord
  hour		= (buffer[0x0b].ord << 8) + buffer[0x0a].ord
  min		= (buffer[0x0d].ord << 8) + buffer[0x0c].ord
  sec		= (buffer[0x0f].ord << 8) + buffer[0x0e].ord

  prodx   	=  buffer[0x18].ord
  major		=  buffer[0x19].ord

  capword 	= (buffer[0x2d].ord << 8) + buffer[0x2c].ord

  capword = 0 if (capword != ((buffer[0x28].ord << 8) + buffer[0x29].ord))

  if (capword & 0x0001) then       # FSC-0039 packet type 2+
    puts "Type 2+ Packet"
    prodx		= prodx + (buffer[0x2a].ord << 8)
    minor		= buffer[0x2b].ord
    orgzone		= buffer[0x2e].ord + (buffer[0x2f].ord << 8)
    destzone		= buffer[0x30].ord + (buffer[0x31].ord << 8)
    orgpoint		= buffer[0x32].ord + (buffer[0x33].ord << 8)
    destpoint		= buffer[0x34].ord + (buffer[0x35].ord << 8)
  end

  pktpwd = ""
  for i in 0..7 do 
    pktpwd << buffer[0x1a + i].ord
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

def add_fido_msg(fidomessage)

  if fidomessage.area == NETMAIL then
    if user_exists(fidomessage.to) then 
      area = fetch_area(0)
     # table = area.number
      number = 0
    else
      number = find_fido_area(BADNETMAIL)
      puts "-FIDO: Bad netmail detected."
      #generate a bounce message
    end
  else
    number = find_fido_area(fidomessage.area)
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

  if !number.nil? then 

    if !pid.nil? then
      pid = pid[0..79] if pid.length > 80
    end

    if !msgid.nil?
      msgid = msgid[0..79] if msgid.length > 80
    end

    puts "----"
    a = fetch_area(number)
    puts "FIDO: importing message to: #{a.name}"

add_msg(m_to,m_from,msg_date,subject,msg_text,exported,network,destnode,destnet,intl,topt,false, f_network,orgnode,orgnet,
               attribute,cost,area,msgid,path,tzutc,charset, tid,pid,fmpt,origin,reply,number)

             #Update pointers
             user = fetch_user(get_uid(FIDOUSER))
             pointer = get_pointer(user,number)
	     scanforaccess(user)
             user.posted = user.posted + 1
             pointer.lastread = high_absolute(number)
             update_user(user)
	     update_pointer(pointer)
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
    add_log_entry(L_ERROR,Time.now,"Fido Import Error: No Packet Found.")
    puts "!No Packet Found"
    #Log Stuff
  when PACKET_IO_ERROR
    puts "!Bad Packet Detected"
    add_log_entry(L_ERROR,Time.now,"Fido Import Error:Bad Packet Detected.")
    #Log Stuff
  when INVALID_PACKET
    puts "!Header Invalid or Not Type 2 or 2+"
    add_log_entry(L_ERROR,Time.now,"Fido Import Error:Header Invalid")
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
