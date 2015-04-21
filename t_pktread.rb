##############################################
#
#   t_pktread.rb --Incomming Packet Processor for Fidomail tosser for QBBS.
#   (C) Copyright 2004, Fly-By-Night Software (Ruby Version)
#
##############################################

include BBS_Logger
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
    @debuglog.push(  "No Area: Netmail Message")
    kludge.area = NETMAIL  # We need to check that the message is really for us?  add this?
  end

  msg_array.each {|x|
    match = (/(^\s\*\sOrigin:)(.+)(\(.+\))/) =~ x
    #puts x
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
    #puts "$1:#{$1} $2:#{$2}"
    if match then
      header = $1
      header.slice!(0)
      value = $2
      if invalid.include? header
        field = header.gsub(/:/, '')
        kludge[field] = value
      else
        valid_messages << x
      end
    end
  end

  #  puts
  #  puts "----"
  return [valid_messages, kludge]
end

def read_a_message(path,offset)

  if File.exists?(path) then
    happy = File.open(path,"rb")
  else
    @debuglog.push(  "File Missing!")
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

  r_loc = offset + pointer + 1	#start of the message text will be a total of the offset and where we stopped
  #reading the header, which varies in size.
  message = ""

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

  #TODO: remove all the commented-out code

 @debuglog.push( "Org:       #{fidomessage.orgnet}/#{fidomessage.orgnode}")
 @debuglog.push( "Dest:      #{fidomessage.destnet}/#{fidomessage.destnode}")
 @debuglog.push( "Attribute: #{fidomessage.attribute}")
 @debuglog.push( "Cost:      #{fidomessage.cost}")
 @debuglog.push( "Date Time: #{fidomessage.datetime}")
 @debuglog.push( "To:        #{fidomessage.to}")
 @debuglog.push( "From:      #{fidomessage.from}")
 @debuglog.push( "Subject:   #{fidomessage.subject}")
 @debuglog.push( "Area:      #{fidomessage.area}") if !fidomessage.area.nil?
 @debuglog.push( "Msgid:     #{fidomessage.msgid}") if !fidomessage.msgid.nil?
 @debuglog.push( "Path:      #{fidomessage.path}") if !fidomessage.path.nil?
 @debuglog.push( "TzUTZ:     #{fidomessage.tzutc}") if !fidomessage.tzutc.nil?
 @debuglog.push( "CharSet:   #{fidomessage.charset}") if !fidomessage.charset.nil?
 @debuglog.push( "Tosser ID: #{fidomessage.tid}") if !fidomessage.tid.nil?
 @debuglog.push( "Proc ID:   #{fidomessage.pid}") if !fidomessage.pid.nil?
 @debuglog.push( "Intl:      #{fidomessage.intl}") if !fidomessage.intl.nil?
 @debuglog.push( "Topt:      #{fidomessage.topt}") if !fidomessage.topt.nil?
 @debuglog.push( "Fmpt:      #{fidomessage.fmpt}") if !fidomessage.fmpt.nil?
 @debuglog.push( "Reply:     #{fidomessage.reply}") if !fidomessage.reply.nil?
 @debuglog.push( "Origin:    #{fidomessage.origin}") if !fidomessage.origin.nil?
 # puts
   puts

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

  #puts "buffer: #{buffer}"
  return INVALID_PACKET if buffer.nil?

  if ((buffer[0x12].ord + (buffer[0x13].ord << 8)) != 2) then
    @debuglog.push( "Not a type 2 packet #{path}")
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
    @debuglog.push(  "Type 2+ Packet")
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
      @debuglog.push("-FIDO: Bad netmail detected.")
      #generate a bounce message  <---- ADD THIS!
    end
  else
    number = find_fido_area(fidomessage.area)
  end

  topt = -1
  topt = fidomessage.topt.to_i if !fidomessage.topt.nil?
  intl = fidomessage.intl
  fmpt = -1
  fmpt = fidomessage.fmpt.to_i if !fidomessage.fmpt.nil?

  if !number.nil? then

   if !fidomessage.pid.nil? then
      fidomessage.pid = fidomessage.pid[0..79] if fidomessage.pid.length > 80
    end

    if !fidomessage.msgid.nil?
      fidomessage.msgid = fidomessage.msgid[0..79] if fidomessage.msgid.length > 80
    end

fidomessage.subject.encode!('UTF-8', 'UTF-8', :invalid => :replace,  :undef => :replace)   if !fidomessage.to.nil?
fidomessage.from.encode!('UTF-8', 'UTF-8', :invalid => :replace,  :undef => :replace)   if !fidomessage.from.nil?
fidomessage.to.encode!('UTF-8', 'UTF-8', :invalid => :replace,  :undef => :replace)   if !fidomessage.subject.nil?
msgout = fidomessage.message.join(DLIM)
msgout.encode!('UTF-8', 'UTF-8', :invalid => :replace)   if !fidomessage.message.nil?

    #puts "----"
    a = fetch_area(number)
    @debuglog.push(  "FIDO: importing message to: #{a.name}")
		    @debuglog.push(  "fidomessage.message: #{fidomessage.message}")
  
    absolute = add_msg(fidomessage.to,
		fidomessage.from,number, :msg_date => fidomessage.datetime.strip, 
		:subject =>fidomessage.subject,
    :msg_text => msgout ,:exported => true, :destnode => fidomessage.destnode,
    :orgnode => fidomessage.orgnode, :orgnet => fidomessage.orgnet, :destnet => fidomessage.destnet,
    :attribute => fidomessage.attribute, :cost => fidomessage.cost, :fntarea => fidomessage.area, :msgid => fidomessage.msgid,
    :path => fidomessage.path, :tzutc => fidomessage.tzutc, :cost => fidomessage.charset, :tid => fidomessage.tid,
    :pid => fidomessage.pid, :orgin => fidomessage.origin, :f_network => true)

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
    @debuglog.push(  "Error: No mapping found for #{fidomessage.area}.  Not Importing")
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
    @debuglog.push(  "!No Packet Found")
    #Log Stuff
  when PACKET_IO_ERROR
    @debuglog.push(  "!Bad Packet Detected")
    add_log_entry(L_ERROR,Time.now,"Fido Import Error:Bad Packet Detected.")
    #Log Stuff
  when INVALID_PACKET
    @debuglog.push(  "!Header Invalid or Not Type 2 or 2+")
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
    add_log_entry(4,Time.now,"#{total} Fido messages imported")
    @debuglog.push( "-FIDO: Import Complete.  #{total} messages imported.")
  end

end #process_packet

