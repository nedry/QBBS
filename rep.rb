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
      outdate = message.msg_date.strftime("%m-%d-%y")
      outtime = message.msg_date.strftime("%H:%M")
      nblocks, msg = message_blocks(message)
      m_to = message.m_to
      m_to = "ALL" if message.m_to.nil? or message.m_to.empty?
      m_subj = message.subject
      m_subj = "No Subject" if message.subject.nil? or message.subject.empty?
      log.write("BLOCKS: #{nblocks}")

      File.open(@file, "a") do |f|
        f.write " "                      # Status Flag (not used on this system)
        f.write conf.to_s.ljust(7)       #Message Number
        f.write outdate.ljust(8)         #Message Date
        f.write outtime.ljust(5)         #Message Time
        f.write m_to.fit(25)     #Message To
        f.write message.m_from.fit(25)   #Message From
        f.write m_subj.fit(25)  #Message Subject
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
      xport =qwk_export_list
      puts "-REP: The following areas have export mappings..."
      xport.each {|x| puts "     #{x.netnum} #{x.name}" }
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

       user = fetch_user(get_uid(u))
       scanforaccess(user)
       pointer = get_pointer(user,xp.number)       
       
        replogandputs "-REP: Last [absolute] Exported Message: #{pointer.lastread}"

        replogandputs "-REP: Highest [absolute] Message: #{high_absolute(xp.number)}"
        replogandputs "-REP: Total Messages            : #{m_total(xp.number)}"
        new = new_messages(xp.number,pointer.lastread)
        replogandputs "-REP: Messages to Export        : #{new}"
	puts 
        if new > 0 then
          #puts "-REP: Starting Export"
	  export_messages(xp.number,pointer.lastread).each {|msg|

              if  !msg.network   then
                writemessage(msg,xp.netnum)
		total += 1
		msg.exported = true
	        update_msg(msg)
              else
                error = msg.network ?
                  "Message has already been imported.":
                  "Message [#{msg.absolute}] doesn't exist."
                m = "Message #{msg.absolute} not exported.  #{error}"
                replogandputs "-#{m}"
                add_log_entry(L_EXPORT,Time.now,"REP Export Complete.")
	end
	}
            end
            puts "-REP: Updating message pointer for board #{xp.name}"
            pointer.lastread = high_absolute(xp.number)
            update_pointer(pointer)
         # end

      }
      add_log_entry(L_EXPORT,Time.now,"Export Complete. #{total} message(s) exported.")
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
