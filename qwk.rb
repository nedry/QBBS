require 'tools'
require 'log'

module Qwk
  Area = Struct.new("Area", :area, :name)

  Message = Struct.new('Message',:error, :statusflag, :number,
                       :date, :to, :from, :subject, :password,
                       :reference, :blocks, :deleted,
                       :logicalnum, :tagline, :text)

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

    def initialize(path)
      @file = path
      @log = Log.new("qwklog.txt")
    end

    def putslog(output)
      log.write(output)
      puts ("-QWK: #{output}")
    end

    def read_index
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

    def getcontrol(path)
      filename = "#{path}/CONTROL.DAT"
      if File.exists?(filename) then
        return IO.readlines(filename)
      else 
        puts "-QWK: Invalid packet. Control.dat not found."
        add_log_entry(8,Time.now,"Invalid QWK packet or Control.dat missing.")
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
        [:tempcrap, 6],
        [:has_tagline, 1]
      ]

      File.open(filename, "rb") do |happy|
        log.write ("SREC  : #{startrec}")
        happy.pos = (startrec) * 128
        msg = {}
        msg_packet.each do |key, len|
          msg[key] = happy.read(len)
          log.write("#{key.to_s.upcase} : #{msg[key]}")
          if message.members.include? key
            message[key] = msg[key]
          end
        end
      end

      # convert numeric fields to integer
      message.reference = message.reference.to_i
      message.blocks = message.blocks.to_i
      message.error = true if message.blocks == 0
      message.tagline = (message.has_tagline == "*")

      # convert date and time to a DateTime object
      message.set_datetime(tempdate, temptime)

      # read blocks
      happy.pos = (startrec + 1) * 128
      if message.blocks > 1 then 
        message.text = happy.read((message.blocks - 1) *128)
      end

      log.write("NSREC : #{startrec + message.blocks}")
      log.write("")
      log.write("ERROR: Corrupt packet detected.") if message.error

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
      list.delete("qwk/PERSONAL.NDX") #we don't want this .. it's dupe causing
      return list
    end

    def printeverything
      i = 0
      for i in 0..(@arealist.len - 1) do
        puts "#{@arealist[i].area} #{@arealist[i].name}"
      end
    end

    def displaypacketstats

      log.write ("#{@totalareas} areas in CONTROL.DAT")
      log.write ("#{idxlist.length} areas found in QWK packet")

      for x in 0..idxlist.length - 1
        y = idxlist[x].scan(/\d\d\d\d/)
        log.write ("#{y} #{@arealist.findarea(y[0].to_i).name}") if @arealist.findarea(y[0].to_i) != nil
      end
    end

    def savemessage(filename)
      File.open(filename, "w+") do |f|
        Marshal.dump(@curmessage, f) ##
      end
    end #savemessage

    def setitup
      user = fetch_user(get_uid(QWKUSER))

      #on first run with database... the user might not have logged in...
      user.lastread = [] if user.lastread == nil

      for i in 0..a_total do
        user.lastread[i] = 0 if user.lastread[i] == nil 
      end
      update_user(user,get_uid(QWKUSER))
    end

    def addmessage(message,area)
      area = fetch_area(area)
      user = fetch_user(get_uid(QWKUSER))
      # @lineeditor.msgtext << DLIM
      #msg_text = message.text.join(DLIM)
      msg_text = message.text
      to = message.to.upcase.strip
      m_from = message.from.upcase.strip
      msg_date = message.date
      title = message.subject.strip
      exported = true
      network = true
      absolute = add_msg(area.tbl,to,m_from,msg_date,title,msg_text,exported,network,false,nil,nil,nil,nil,false)

      user.posted = user.posted + 1
      user.lastread[area.number] = absolute
      update_user(user,get_uid(QWKUSER))
    end

    def scanpacket (index,name)
      print "-QWK: Scanning Message #" 

      boom = false
      x = 0
      index.each {|happy| 
        x = x + 1
        message = getmessage("qwk",happy)
        if message.error then
          puts
          puts "-QWK: ERROR detected in packet.  Aborting."
          add_log_entry(8,Time.now,"Error in QWK packet. #{name} Packet skipped.")
          boom = true
          break
        else
          print x
          $stdout.flush
          x.to_s.length.times { print(BS.chr) }
        end
      }

      puts 
      puts "-QWK: Packet OK." if !boom

      return boom		  
    end

    def clearoldqwk
      puts "-QWK: Deleting old packets"
      happy = system("rm qwk/*")
      if happy then 
        puts "-Success" 
      else 
        add_log_entry(4,Time.now,"WARNING: Failed to delete old packets.  This could be normal.")
        puts "QWK: -Failure" 
      end
    end

    def ftppacketdown
      begin
        ftp = Net::FTP.new(FTPADDRESS)
        ftp.debug_mode = true
        ftp.passive = true
        ftp.login(FTPACCOUNT,FTPPASSWORD)
        ftp.getbinaryfile(QWKPACKETDOWN,QWKPACKET,1024)
        ftp.close
        add_log_entry(4,Time.now,"QWK Packet Download Successfull")
        puts "-QWK: Download Successful"
      rescue
        puts "-ERROR!!!... In FTP Download"
        add_log_entry(4,Time.now,"QWK Packet Download Failure. No new msgs?")
      end
    end

    def unzippacket
      happy = system("unzip #{QWKPACKET} -d #{QWKDIR}")
      add_log_entry(8,Time.now,"Could not unzip QWK Packet.") if !happy
    end

    def import
      relog.write
      ddate = Time.now.strftime("%m/%d/%Y at %I:%M%p") 
      puts "-QWK: Starting import."
      add_log_entry(4,Time.now,"Starting QWK message import")
      clearoldqwk
      ftppacketdown
      unzippacket

      idxlist = getindexlist("qwk/*.NDX")
      control = getcontrol("qwk")
      makearealist(control)
      displaypacketstats
      setitup

      tmsgimport = 0

      idxlist.each do |idx|

        index = read_index(idx)

        putslog ("Now Processing Packet #{idx} which contains #{index.length} messages.")
        log.write ("")
        tempstr = idx.scan(/\d\d\d\d/)
        find = tempstr[0].to_i
        puts "-QWK: Finding Import Area for packet# #{find}..."
        destnum = (find == 0) ? 0 : find_qwk_area(find, nil) 
        if destnum
          area = fetch_area(destnum)
          putslog "Found. Importing #{idx} to #{area.name}"
          puts
          x = 0
          boom = scanpacket(index, idx)
          if !boom then 
            print "-QWK: Processing Message #" 

            index.each_with_index {|happy, x| 
              tmsgimport = tmsgimport.succ
              message = getmessage("qwk",happy)
              if message.error then
                puts
                puts "-QWK: ERROR detected in packet.  Aborting."
                break
              else
                print x
                $stdout.flush
                x.to_s.length.times { print(BS.chr) }
                addmessage(message,destnum) 
              end
            }
          end
        else
          puts
          putslog "QWK: ERROR: No mapping found for area #{idx}"
          puts
          add_log_entry(8,Time.now,"No QWK mapping found for area #{idx}")
        end
        puts

      end
      add_log_entry(4,Time.now,"Import Complete. #{tmsgimport} message(s) imported.")
      puts "-QWK: import complete."
    end #of def Qwkimport

  end
end
