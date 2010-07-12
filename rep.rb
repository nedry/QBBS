require 'tools'
require 'log'
require 'ftpclient'
require 'db/db_log'
require 'encodings.rb'

module Rep
  class Exporter
    attr_accessor :file, :log

    def initialize(path)
      @file = path
      @log = Log.new("replog.txt")
    end

    def writeheader
      File.open(file, "ab") do |f|
        f.write BBSID.ljust(128)
      end
    end

    def reformat_date(datein)
      temp = datein.to_s.split(' ')
      puts "datetmp: #{temp}"
      date_arr = temp[0].split('-')
      year = date_arr[0]
      output = "#{date_arr[1]}-#{date_arr[2]}-#{year[2..3]}"
      return output
    end

    def reformat_time(timein)
      temp = timein.to_s.split(' ')
      puts "timetmp: #{temp}"
      time = temp[1]
      output = time[0..4]
      return output
    end

    def log_message(message)
      log.write("DATE  : #{message.msg_date}")
      log.write("TO    : #{message.m_to}")
      log.write("FROM  : #{message.m_from}")
      log.write("SUBJ  : #{message.subject}")
    end

    def message_blocks(message)
      outmessage = convert_to_ascii(message.msg_text) # .join('?)
      outmessage.gsub!(DLIM,227.chr)
      outmessage = outmessage << 227.chr << "---" <<227.chr
      outmessage = outmessage << QWKTAG << 227.chr
      dec = outmessage.length / 128
      nblocks = (dec.succ)
      len = outmessage.length
      total = nblocks * 128
      out2 = outmessage.ljust(total)
      nblocks += 1  #Add one because this stupid system thinks a header is a block
      return [nblocks, out2]
    end

    def writemessage(message, conf)
      log_message(message)
      outdate = reformat_date(message.msg_date)
      outtime = reformat_time(message.msg_date)
      nblocks, msg = message_blocks(message)
      log.write("BLOCKS: #{blocks}")

      File.open(@file, "a") do |f|
        f.write " "                      # Status Flag (not used on this system)
        f.write conf.to_s.ljust(7)       #Message Number
        f.write outdate.ljust(8)         #Message Date
        f.write outtime.ljust(5)         #Message Time
        f.write message.m_to.fit(25)     #Message To
        f.write message.m_from.fit(25)   #Message From
        f.write message.subject.fit(25)  #Message Subject
        f.write "".ljust(12)             #Message Password (not used on this system)
        f.write "".ljust(8)              #Message Reference (not used on this system)
        f.write nblocks.to_s.ljust(6)    #Message 128 byte blocks
        f.write "".ljust(5)              #Some other crap I hope I can get away with ignoring
        f.write "*"                      #Message tagline = true
        f.write msg
      end
    end

 def replogandputs(m)
   @log.write(m)
   puts m
 end

    def makeexportlist
      xport = rep_table("").sort_by {|a| a.xnum}
      puts "-REP: The following areas have export mappings..."
      xport.each {|x| puts "     #{x.xnum} #{x.name}" }
      return xport
    end

    def ftppacketup
      ftp = FtpClient.new(FTPADDRESS, FTPACCOUNT, FTPPASSWORD)
      ftp.rep_packet_up
    end

    def clearoldrep
      puts "-REP: Deleting old packets"
      File.delete(REPDATA) if File.exists?(REPDATA)
      File.delete(REPPACKET) if File.exists?(REPPACKET)
    end

    def repexport(u)
      clearoldrep
      ddate = Time.now.strftime("%m/%d/%Y at %I:%M%p")
      puts "-REP: Starting export."
      add_log_entry(3,Time.now,"Starting QWK message export.")
      @log.rewrite!
      writeheader
      total = 0
      makeexportlist.each {|xp|
        puts "-REP: Now Processing #{xp.name} message area."
	@log.write "-REP: Now Processing #{xp.name} message area."

        #on first run with database... the user might not have logged in...
       user = fetch_user(get_uid(u))
       scanforaccess(user)
       area = fetch_area(xp.num)
       pointer = get_pointer(user,xp.num)       
       
        replogandputs "-REP: Last [absolute] Exported Message: #{pointer.lastread}"

        replogandputs "-REP: Highest [absolute] Message: #{high_absolute(area.number)}"
        replogandputs "-REP: Total Messages            : #{m_total(area.number)}"
        new = new_messages(area.number,pointer.lastread)
        replogandputs "-REP: Messages to Export        : #{new}"
	puts 
        if new > 0 then
          #puts "-REP: Starting Export"
          for i in pointer.lastread.succ..high_absolute(area.number) do
            workingmessage = fetch_msg(i)
            if workingmessage != nil then
              if  !workingmessage.network then
                writemessage(workingmessage,xp.xnum)
                total = total.succ
              else
                error = workingmessage.network ?
                  "Message has already been imported.":
                  "Message [#{i}] doesn't exist."
                m = "Message #{i} not exported.  #{error}"
                replogandputs "-#{m}"
                add_log_entry(3,Time.now,"REP Export Complete.")
              end
            end
            puts "-REP: Updating message pointer for board #{xp.name}"
            n = xp.num
            pointer.lastread = high_absolute(area.number)
            update_pointer(pointer)
          end
        end
      }
      add_log_entry(3,Time.now,"Export Complete. #{total} message(s) exported.")
      puts "-REP: Export Complete. #{total} message(s) exported."
      puts
      puts "-REP: Compressing Packet"
      happy = system("zip -j -D #{REPPACKET} #{REPDATA}")
      if happy then
        worked = ftppacketup
        return worked
      else
        add_log_entry(8,Time.now,"Failed to zip REP packet.")
        return false
      end
    end
  end
end
