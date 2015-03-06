class FidomailPacketWriter

  require "db/db_system"
  require "db/db_log"

  def initialize(writer)
    #  @writer = writer
  end


  def write_pkt_header(f_hdr)
      buffer = "".force_encoding("ASCII-8BIT")
	    # pos 0
      buffer << (f_hdr.orgnode & 0x00ff) 
			buffer << ((f_hdr.orgnode & 0xff00) >> 8) 
		  # pos 2
			buffer <<  (f_hdr.destnode & 0x00ff) 
      buffer << ((f_hdr.destnode & 0xff00) >> 8) 
	    #pos 4
      buffer << (f_hdr.year & 0x00ff) 
      buffer << ((f_hdr.year & 0xff00) >> 8) 
      #pos 6
      buffer << f_hdr.month - 1 << 0 
      #pos 8 
      buffer << f_hdr.day << 0 
      #pos 10
      buffer << f_hdr.hour << 0 
      #pos 12 
      buffer << f_hdr.min << 0 
      #pos 14
       buffer << f_hdr.sec << 0 
			#pos 16 (baud)   
  buffer << 0 << 0 
 #pos 18
	buffer << 2 << 0 
 #pos 20
  buffer << (f_hdr.orgnet & 0x00ff) 
  buffer << ((f_hdr.orgnet & 0xff00) >> 8) 
 #pos 22   
  buffer << (f_hdr.destnet & 0x00ff) 
  buffer << ((f_hdr.destnet & 0xff00) >> 8) 
  #pos 24 (product code / revision) 
  buffer << 255 
	buffer << 1 
	#pos 26
  total = 8 
  password = f_hdr.password 
  password = password[0..7] if password.length > 8  
  nuls = total - password.length 
  buffer <<  password.strip 
  nuls.times {buffer << 0} 
  #pos 34  
  buffer << ((f_hdr.orgzone & 0x00ff)) 
  buffer << ((f_hdr.orgzone & 0xff00) >> 8) 
 #pos 36
  buffer << ((f_hdr.destzone & 0x00ff)) 
  buffer << ((f_hdr.destzone & 0xff00) >> 8) 
 #pos 38 (auxnet)
  buffer << 0 << 0 
 #pos 40 (CW Validation)  
  buffer << 0 << 1 
#pos 42 (Product Code)
  buffer << 0 << 0 
#pos 44 (Capibility Word)
  buffer << 1  << 0 
 #pos 46
  buffer << ((f_hdr.orgzone & 0x00ff)) 
  buffer << ((f_hdr.orgzone & 0xff00) >> 8) 
#pos 48
  buffer << ((f_hdr.destzone & 0x00ff)) 
  buffer << ((f_hdr.destzone & 0xff00) >> 8) 
# pos 50
  buffer << (f_hdr.orgpoint & 0x00ff) 
  buffer << ((f_hdr.orgpoint & 0xff00) >> 8) 
 #pos 52  
  buffer << (f_hdr.destpoint & 0x00ff) 
  buffer << ((f_hdr.destpoint & 0xff00) >> 8) 
# pos 54 (product specific data)
  buffer << 0 << 0 << 0 << 0 
# pos 58 (end of packet header)


    @writer.write buffer
  end


  def write_nul_delimited(buffer,output,max)
		output = " " if output.nil?
    output = output[0..max - 1] if output.length > max
    buffer <<  output << 0
    return buffer
  end

  def add_kludge_lines(buffer,area,msgid,tzutc,charset,tid,fmpt,reply,topt,intl)


    # TODO: have an add_to_buffer(buffer, header, data) function that does the
    # if data.nil? check internally. then rewrite as
    # [["MSGID: ", msgid],
    #  ["TZUTC: ", tzutc]
    #  ...
    #  ].each {|header, data| add_to_buffer(buffer, header, data)}
    if !area.nil? and area != NETMAIL then
      buffer << "AREA:" << area << CR.chr
    end
    if !msgid.nil? then
      buffer << 1 << "MSGID: " <<msgid << CR.chr
    end
    if !tzutc.nil? then
      buffer << 1 << "TZUTC: " <<tzutc << CR.chr
    end
    if !charset.nil? then
      buffer << 1 << "CHARSET: " << charset << CR.chr
    end
    if !tid.nil? then
      buffer << 1 << "TID: " << tid << CR.chr
    end
    if !fmpt.nil? then
      buffer << 1 << "FMPT " << fmpt.to_s << CR.chr
    end
    if !reply.nil? then
      buffer << 1 << "REPLY: " << reply << CR.chr
    end
    if !topt.nil? then
			if topt > 0 then 
        buffer << 1 << "TOPT " << topt.to_s << CR.chr
			end
    end
    if !intl.nil? then
      buffer << 1 << "INTL " << intl << CR.chr
    end
    return buffer
  end

  def write_pkt_end
    @writer.write('' << 0 << 0)
    @writer.close
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

  def write_a_message(table,f_area,msg)
    system = fetch_system
    system.f_msgid  +=1
    n_msgid = system.f_msgid.to_s(16)
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
    reply = nil
    reply = msg.msgid if f_network
    origin = nil
    smtp = false

		buffer =''.force_encoding("ASCII-8BIT")
    buffer << 2 << 0
    buffer << (orgnode & 0x00ff)
		buffer << ((orgnode & 0xff00) >> 8)

    buffer << (destnode & 0x00ff)
    buffer << ((destnode & 0xff00) >> 8)
  
    buffer << (orgnet & 0x00ff)
    buffer << ((orgnet & 0xff00) >> 8)

     buffer << (destnet & 0x00ff)
     buffer << ((destnet & 0xff00) >> 8)
  
     buffer << (attribute & 0x00ff)
     buffer << ((attribute & 0xff00) >> 8)
 
     buffer << (cost & 0x00ff)
     buffer << ((cost & 0xff00) >> 8)
		 
    datetime = msg_date.strftime ("%d %b %y  %H:%M:%S")
    buffer << datetime.fit(19)
    buffer << 0

    buffer = write_nul_delimited(buffer,m_to,35)
    buffer = write_nul_delimited(buffer,m_from,35)
    buffer = write_nul_delimited(buffer,subject,35)
    # message.msg_text.gsub!('ã',CR.chr)
    #message.msg_text.gsub!(DLIM,CR.chr)
    buffer = add_kludge_lines(buffer,area,msgid,tzutc,charset,tid,fmpt,reply,topt,intl)
    buffer << msg_text << CR.chr

    if area != NETMAIL then
      buffer << TEAR << CR.chr
      buffer << ORGIN << CR.chr
    end
    buffer << 0
    @writer.write buffer

  end

  def open_pkt(path)
    begin
      @writer = File.new("#{path}", "ab", 0644)
    rescue
      puts "Error writing file."
      return PACKET_CREATE_ERROR
    end
  end

end
