require 'tools'
require 'log'
require 'ftpclient'
require 'db/db_log'
require 'encodings.rb'


module Qwk
  Area = Struct.new("Area", :area, :name)

  Message = Struct.new('Message',:error, :statusflag, :number,
                       :date, :to, :from, :subject, :password,
                       :reference, :blocks, :deleted,
                       :logicalnum, :tagline, :text, :msgid, :via, :tz, :reply)

  class Message
    private :initialize
    class << self
      def create
        a = self.new
        a.error = false
        a.statusflag = ''
        a.number = 0
        a.date = Time.new
        a.to = ''
        a.from = ''
        a.subject = ''
        a.password = ''
        a.reference = 0
        a.blocks = 0
        a.deleted = false
        a.logicalnum = 0
        a.tagline = false
        a.text = []
        a.msgid = ''
        a.via = ''
        a.tz = ''
        a.reply = ''
        
        
        return a
      end
    end

    def set_datetime(string_date, string_time)
      # postprocess date and time read in from file
      month, day, year = string_date.split('-').map {|x| x.to_i}
      year = (year < 70) ? year + 2000 : year + 1900 # epoch starts at 1970
      hour, min = string_time.split(':').map {|x| x.to_i}

      if (year < 1996) or (year > 2010) then year = 2000 end # why?!

      if (month == 0) or (day == 0)
        self.error = true 
      else 
        self.date = Time.gm(year,month,day,hour,min) 
      end
    end
  end

  class Arealist
    def initialize
      @arealist_qwk = []
    end

    def append(aArea) 
      @arealist_qwk.push(aArea) 
    end 

    def [](key) 
      key.kind_of?(Integer) ? @arealist_qwk[key] :
        @arealist_qwk.find {|arealist| key == arealist.name} 
    end 

    def findarea(key) 
      @arealist_qwk.find { |arealist| key == arealist.area } 
    end

    def len
      @arealist_qwk.length 
    end
  end

  class Importer
    attr_accessor :file, :log
    
   def initialize(qwknet)
      @qwknet = qwknet
      @log = Log.new("qwklog.txt")
    end
    
    def putslog(output)
      @log.write(output)
      puts ("-QWK: #{output}")
    end

    def read_index(file)
      index = []
      unless File.exists?(file)
        puts "-QWK: NDX File not found!"
        return nil
      end

      File.open(file, "rb") do |f|
        f.pos = 0
        while true
          break if f.eof
          raw = f.read(5)
          bytes = raw.each_byte.to_a.reverse
          n = 0
          bytes.each {|i| n = n*256 + i}
          shift = 24-((n>>24) & 0x7f)
          n = (n & 0x00ffffff) | 0x00800000
          index.push((n >> shift)-1)
        end

        return index
      end
    end


class Q_Kludge
 attr_accessor  :msgid, :tz, :via, :reply

 def initialize (msgid=nil,tz=nil,via=nil,reply=nil)
  @msgid	= msgid
  @tz   	= tz
  @via	= via
  @reply	= reply
 end

 def []=(field, value)
   field = field.downcase
   self.send("#{field}=", value)
 end

end #of class Kludge

 def qwk_kludge_search(buffer)	#searches the message buffer for kludge lines and returns them
  kludge = Q_Kludge.new

  msg_array = buffer.split(227.chr)  #split the message into an array so we can deal with it.

  
  # if we find any of these, reject the message
  invalid = ["@MSGID:", "@VIA:", "@TZ:", "@REPLY:"]

  valid_messages = []
  msg_array.each do |x|
    match = (/^(\S*)(.*)/) =~ x
    if match then
      header = $1
      value = $2
      if invalid.include? header
        temp = header.gsub(/:/, '')
	field = temp.gsub(/@/,'')
        kludge[field] = value.strip!
      else
        valid_messages << x
      end
    end
  end

  return [valid_messages.join(227.chr) , kludge]
end

    def getcontrol(path)
      filename = "#{path}/CONTROL.DAT"
      if File.exists?(filename) then
        return IO.readlines(filename)
      else 
        puts "-QWK: Invalid packet. Control.dat not found."
        add_log_entry(8,Time.now,"Invalid QWK packet or Control.dat.")
        return []
      end
    end

    def getmessage(path, startrec)
      message = Message.create
      filename = "#{path}/MESSAGES.DAT"

      unless File.exists?(filename)
        message.error = true
        return message
      end

      msg_packet = [
        [:statusflag, 1],
        [:number, 7],
        [:tempdate, 8],
        [:temptime, 5],
        [:to, 25],
        [:from, 25],
        [:subject, 25],
        [:password, 12],
        [:reference, 8],
        [:blocks, 6],
        [:tempcrap, 5],
        [:has_tagline, 1]
      ]

      msg = {} # stores the raw message fields as we read them in

      File.open(filename, "rb") do |file|
        @log.write ("SREC  : #{startrec}")
        file.pos = (startrec) * 128
        msg_packet.each do |key, len|
          msg[key] = file.read(len)
          @log.write("#{key.to_s.upcase} : #{msg[key]}")
          if message.members.include? key
            message[key] = msg[key]
          end
        end

        # convert numeric fields to integer
        message.reference = message.reference.to_i
        message.blocks = message.blocks.to_i
        message.error = true if message.blocks == 0

        # convert tagline to a boolean (if there is a "*" we have a tagline)
        message.tagline = (message.tagline == "*")

        # convert date and time to a DateTime object
        message.set_datetime(msg[:tempdate], msg[:temptime])

        # read blocks
        file.pos = (startrec + 1) * 128
        if message.blocks > 1 then

          temp = file.read((message.blocks - 1) * 128)
          dekludgify, kludge = qwk_kludge_search(temp)
	        message.text = convert_to_utf8(dekludgify)
          if !kludge.nil? then
            message.via = kludge.via
            message.tz = kludge.tz
            message.reply = kludge.reply
            message.msgid = kludge.msgid
          end
 
        end
      end
     @log.write("NSREC : #{startrec + message.blocks}")

      @log.write("")
      @log.write("ERROR: Corrupt packet detected.") if message.error

      return message
    end

    def makearealist(list)
      i = 13
      @arealist = Arealist.new
      num = list[10].to_i # defaults to 0 if list is too short
      @totalareas = num
      num = num * 2 + 13
      if num > 0 then
        while i < num 
          temp1 = list[i].to_i
          i = i + 1
          temp2 = list[i]
          i = i + 1
          @arealist.append(Area.new(temp1,temp2))
        end
      else 
        puts "-QWK: Invalid packet.  Control.dat truncated!"
      end
    end

    def getindexlist(path)
      list = Dir.glob(path)
      list.delete("@/PERSONAL.NDX") #we don't want this .. it's dupe causing
      return list
    end

    def printeverything
      i = 0
      for i in 0..(@arealist.len - 1) do
        puts "#{@arealist[i].area} #{@arealist[i].name}"
      end
    end

    def displaypacketstats(idxlist)

      @log.write ("#{@totalareas} areas in CONTROL.DAT")
      @log.write ("#{idxlist.length} areas found in QWK packet")

      for x in 0..idxlist.length - 1
        y = idxlist[x].scan(/\d\d\d\d/)
        @log.write ("#{y} #{@arealist.findarea(y[0].to_i).name}") if @arealist.findarea(y[0].to_i) != nil
      end
    end

    def savemessage(filename)
      File.open(filename, "w+") do |f|
        Marshal.dump(@curmessage, f) ##
      end
    end #savemessage

    def clearoldqwk
      puts "-QWK: Deleting old packets"
      happy = system("rm #{@qwknet.qwkdir}/*")
      if happy then 
        puts "-Success" 
      else 
        add_log_entry(4,Time.now,"No old packets to delete.")
        puts "-QWK: No old packets to delete." 
      end
    end

    def ftppacketdown
      ftp = FtpClient.new(@qwknet)
      ftp.qwk_packet_down
    end

    def unzippacket
      happy = system("unzip #{@qwknet.qwkdir}/#{@qwknet.qwkpacket} -d #{@qwknet.qwkdir}")
      add_log_entry(8,Time.now,"Could not unzip QWK Packet.") if !happy
    end

    def read_messages(index)
      n_read = 0
      index.each_with_index do |msg_index, x|
        n_read += 1
        message = getmessage(@qwknet.qwkdir, msg_index)
        if message.error then
          puts
          puts "-QWK: ERROR detected in packet.  Aborting."
          break
        else
          print x
          $stdout.flush
          x.to_s.length.times { print(BS.chr) }
          yield message
        end
      end
      return n_read
    end

    def import
      #relog.write
      ddate = Time.now.strftime("%m/%d/%Y at %I:%M%p") 
      puts "-QWK: Starting import."
      add_log_entry(4,Time.now,"Starting QWK message import")
      if !QWK_DEBUG then
       clearoldqwk
       ftppacketdown
       unzippacket
      end

      idxlist = getindexlist("#{@qwknet.qwkdir}/*.NDX")
      control = getcontrol(@qwknet.qwkdir)
      makearealist(control)
      displaypacketstats(idxlist)

      user = fetch_user(get_uid(@qwknet.qwkuser))
      scanforaccess(user)
      tmsgimport = 0

      idxlist.each do |idx|

        index = read_index(idx)

        @log.write ("Now Processing Packet #{idx} which contains #{index.length} messages.")
        @log.write ("")
        tempstr = idx.scan(/\d\d\d\d/)
        find = tempstr[0].to_i
        puts "-QWK: Seeking Import Area for packet# #{find}..."
        if find > 0 then
         area =  find_qwk_area(find,@qwknet.grp) 
        else
          area = fetch_area(0)  #we want to import all email into email.  QWK/REP email is always 000
        end
        if area
          @log.write "Found! Importing #{idx} to #{area.name}"
          puts "-QWK: Found. Importing #{idx} to #{area.name}"
          puts
          x = 0
          print "-QWK: Processing Message #"

          read_messages(index) do |message|
            add_qwk_message(message, area,@qwknet.qwkuser) # in db_message
          end
        else
          puts
          putslog "ERROR: No mapping found for area #{idx}"
          puts
          add_log_entry(8,Time.now,"No QWK mapping for area #{idx}")
        end
        puts

      end
      add_log_entry(4,Time.now,"Import Complete. #{tmsgimport} message(s) imported.")
      puts "-QWK: Import complete."
    end #of def Qwkimport

  end
end
