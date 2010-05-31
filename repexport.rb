include Logger
require "tools.rb"

def rewritereplog
  rewritelog('replog.txt')
end

def writereplog(line)
  lf = File.new("replog.txt", File::CREAT|File::APPEND|File::RDWR, 0644)
  lf.puts line
  lf.close
end

def writeheader
  filename = "#{REPDATA}"
  if !File.exists?(filename) then
    happy = File.open(filename,"ab")
    happy.write BBSID.ljust(128)
    happy.close
  end
end

def reformat_date(datein)
  temp=datein.split(' ')
  date_arr = temp[0].split('-')
  year = date_arr[0]
  output = "#{date_arr[1]}-#{date_arr[2]}-#{year[2..3]}"
  return output
end

def reformat_time(timein)
  temp=timein.split(' ')
  time = temp[1]
  output = time[0..4]
  puts "output:#{output}"
  puts timein
  return output

end


def writemessage(path,message,conf)
  filename = "#{REPDATA}"
  if File.exists?(filename) then
    happy = File.open(filename,"a")
    #writeqwklog ("SREC  : #{startrec}")
    happy.write " "            # Status Flag (not used on this system)
    happy.write conf.to_s.ljust(7)       #Message Number
    outdate = reformat_date(message.msg_date)
    happy.write outdate.ljust(8)  #Message Date
    writereplog("DATE : #{message.msg_date}")
    outtime = reformat_time(message.msg_date)
    happy.write outtime.ljust(5)  #Message Time
    happy.write message.m_to.fit(25)   #Message To
    writereplog("TO    : #{message.m_to}")
    happy.write message.m_from.fit(25)   #Message From
    writereplog("FROM  : #{message.m_from}")
    happy.write message.subject.fit(25)   #Message Subject
    writereplog("SUBJ  : #{message.subject}")
    happy.write "".ljust(12)   #Message Password (not used on this system)
    happy.write "".ljust(8)    #Message Reference (not used on this system)
    #puts message.msg_text
    outmessage = message.msg_text # .join('?)

    #outmessage = outmessage << "�---"
    #outmessage = outmessage << "�#{QWKTAG}"
    #outmessage = outmessage << "�"

    outmessage = outmessage << DLIM << "---" << DLIM
    outmessage = outmessage<< QWKTAG << DLIM
    #	outmessage = outmessage <<  254.chr  
    dec = outmessage.length / 128
    blocks = (dec.succ)
    len = outmessage.length
    total = blocks * 128
    out2 = outmessage.ljust(total)
    blocks += 1  #Add one because this stupid system thinks a header is a block
    happy.write blocks.to_s.ljust(6)         #Message 128 byte blocks
    writereplog("BLOCKS: #{blocks}")
    happy.write "".ljust(5)  #Some other crap I hope I can get away with ignoring
    happy.write "*"        #Message tagline = true
    happy.write out2
    happy.close
  end
end

def makeexportlist
  xport = rep_table("")

  xport.sort! {|a, b| a.xnum <=> b.xnum}

  #writereplog ("-The following areas have export mappings...")
  puts "-REP: The following areas have export mappings..."

  xport.each_index {|j|
    puts "     #{xport[j].xnum} #{xport[j].name}"
  }
  #writereplog(" ")
  #puts
  return xport
end

def ftppacketup
  begin
    ftp = Net::FTP.new(FTPADDRESS)
    ftp.debug_mode = true
    ftp.passive = true
    ftp.login(FTPACCOUNT,FTPPASSWORD)
    ftp.putbinaryfile(REPPACKET, REPPACKETUP, 1024)
    ftp.close
    add_log_entry(3,Time.now,"FTP QWK upload success.")
    puts "-REP: FTP QWK Upload Successful"
    return true
  rescue
    puts "-ERROR!!!... In FTP Upload"
    add_log_entry(8,Time.now," FTP QWK Upload Failure.")
    return false
  end
end

def clearoldrep
  puts "-REP: Deleting old packets"
  File.delete(REPDATA) if File.exists?(REPDATA)
  File.delete(REPPACKET) if File.exists?(REPPACKET)
end

def loadmessage(filename)
  puts "-Loading Message Number: #{filename}"
  curmessage = Amessage.newblank
  if File.exists?(filename)
    File.open(filename) do |f|
      curmessage = Marshal.load(f)
    end
  else
    puts "-Message not found.  Please panic!"
  end
  return curmessage
end #loadmessage

def repexport
  clearoldrep
  user = fetch_user(get_uid(QWKUSER))
  ddate = Time.now.strftime("%m/%d/%Y at %I:%M%p")
  puts "-REP: Starting export."
  add_log_entry(3,Time.now,"Starting QWK message export.")
  xport = makeexportlist
  rewritereplog
  writeheader
  total = 0
  xport.each {|xp|
    replogandputs "-REP: Now Processing #{xp.name} message area."

    #on first run with database... the user might not have logged in...
    user.lastread = [] if user.lastread == nil

    pointer = user.lastread[xp.num] || 0
    replogandputs "-REP: Last [absolute] Exported Message: #{pointer}"
    area = fetch_area(xp.num)
    replogandputs "-REP: Highest [absolute] Message: #{high_absolute(area.tbl)}"
    replogandputs "-REP: Total Messages       : #{m_total(area.tbl)}"
    new = new_messages(area.tbl,pointer)
    replogandputs "-REP: Messages to Export   : #{new}"
    if new > 0 then
      #puts "-REP: Starting Export"
      for i in pointer.succ..high_absolute(area.tbl) do
        workingmessage = fetch_msg(area.tbl,i)
        if workingmessage != nil then 
          if  !workingmessage.network then
            writemessage("rep/",workingmessage,xp.xnum)
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
        user.lastread[n] = high_absolute(area.tbl)
        update_user(user,get_uid(QWKUSER))
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
