require 'tools'
require 'log'
require 'ftpclient'
require 'db/db_log'
require 'db/db_message'
require 'encodings.rb'

module Rep
  class Exporter
    attr_accessor :file, :log

    def initialize(qwknet,debuglog)
      @qwknet = qwknet
      @log = Log.new("replog.txt")
      @repdata = "#{@qwknet.repdir}/#{@qwknet.repdata}"
      @reppacket = "#{@qwknet.repdir}/#{@qwknet.reppacket}"
      @debuglog = debuglog
    end

    def writeheader
      File.open(@repdata, "ab") do |f|
        f.write @qwknet.bbsid.ljust(128)
      end
    end


    def convert_to_ansi(line)
      COLORTABLE.each_pair {|color, result| line.gsub!(color,result) }
      return line
    end

    def log_message(message)
      log.write("DATE  : #{message.msg_date}")
      log.write("TO    : #{message.m_to}")
      log.write("FROM  : #{message.m_from}")
      log.write("SUBJ  : #{message.subject}")
    end

    def message_blocks(message)
      outmessage = convert_to_ascii(message.msg_text) # .join('?)
      outmessage = convert_to_ansi(outmessage)
      outmessage.gsub!(DLIM,227.chr)
      outmessage = outmessage << 227.chr << "---" <<227.chr
      outmessage = outmessage << convert_to_ascii(@qwknet.qwktag) << 227.chr
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

      File.open(@repdata, "a") do |f|
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
      @debuglog.push(m)
    end

    def makeexportlist
      xport =qwk_export_list(@qwknet.grp)
      @debuglog.push( "-REP: The following areas have export mappings...")
      xport.each {|x| @debuglog.push( "     #{x.netnum} #{x.name}" )}
      return xport
    end

    def ftppacketup
      ftp = FtpClient.new(@qwknet,@debuglog)
      ftp.rep_packet_up
    end

    def clearoldrep
      @debuglog.push("-REP: Deleting old packets")

      File.delete(@repdata) if File.exists?(@repdata)
      File.delete(@reppacket) if File.exists?(@reppacket)
    end

    def repexport
      clearoldrep
      ddate = Time.now.strftime("%m/%d/%Y at %I:%M%p")
      @debuglog.push( "-REP: Starting export.")
      add_log_entry(3,Time.now,"Starting QWK message export.")
      @log.rewrite!
      writeheader
      total = 0
      makeexportlist.each {|xp|
        @debuglog.push( "-REP: Now Processing #{xp.name} message area.")
        @log.write "-REP: Now Processing #{xp.name} message area."

        user = fetch_user(get_uid(@qwknet.qwkuser))
        scanforaccess(user)
        pointer = get_pointer(user,xp.number)

        replogandputs "-REP: Last [absolute] Exported Message...#{pointer.lastread}"

        replogandputs "-REP: Highest [absolute] Message.........#{high_absolute(xp.number)}"
        replogandputs "-REP: Total Messages.....................#{m_total(xp.number)}"
        new = new_messages(xp.number,pointer.lastread)
        replogandputs "-REP: Messages to Export.................#{new}"

        if new > 0 then

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
        @debuglog.push( "-REP: Updating message pointer for board #{xp.name}")
        pointer.lastread = high_absolute(xp.number)
        update_pointer(pointer)
        # end

      }
      add_log_entry(L_EXPORT,Time.now,"Export Complete. #{total} message(s) exported.")
      @debuglog.push( "-REP: Export Complete. #{total} message(s) exported.")

      @debuglog.push("-REP: Compressing Packet")
      happy = system("zip -j -D #{@reppacket} #{@repdata} > /dev/null 2>&1")
      if happy then
        worked = ftppacketup
        return worked
      else
        add_log_entry(8,Time.now,"Failed to zip REP packet.")
        @debuglog.push("-REP: Failed to zip REP packet.")
        return false
      end
    end
  end
end
