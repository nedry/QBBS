class FidomailPacketWriter

  require "db/db_system"
  require "db/db_log"

  def initialize(writer)
    #  @writer = writer
  end

  def bytes(*args)
    buffer = ''
    args.each {|x|
      buffer << (x & 0x0ff) << ((x & 0xff00) >> 8)
    }
    buffer
  end

  def write_pkt_header(f_hdr)
    buffer = ''
    buffer << bytes(f_hdr.orgnode, f_hdr.destnode, f_hdr.year)

    [f_hdr.month - 1, f_hdr.day, f_hdr.hour, f_hdr.min, f_hdr.sec].each {|i|
      buffer << i << 0
    }

    buffer << 0 << 0 << 2 << 0

    buffer << bytes(f_hdr.orgnet, f_hdr.destnet)

    buffer << 255

    buffer << 1
    total = 8
    password = f_hdr.password
    password = password[0..7] if password.length > 8
    nuls = total - password.length
    buffer <<  password.strip
    nuls.times {buffer << 0}

    buffer << bytes(f_hdr.orgzone, f_hdr.destzone)
    buffer << 0 << 0 << 0
    buffer << 1
    buffer << 0 << 0
    buffer << 1 << 0

    buffer << bytes(f_hdr.orgzone, f_hdr.destzone, f_hdr.orgpoint, f_hdr.destpoint)
    buffer << 0 << 0 << 0 << 0

    @writer.write buffer
  end


  def write_nul_delimited(buffer,output,max)
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
      buffer << 1 << "TOPT " << topt.to_s << CR.chr
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

    buffer =''
    buffer << 2 << 0
    buffer << bytes(orgnode, destnode, orgnet, destnet, attribute, cost)

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
      @writer = File.new("#{path}", File::CREAT|File::RDWR, 0644)
    rescue
      puts "Error writing file."
      return PACKET_CREATE_ERROR
    end
  end

end
