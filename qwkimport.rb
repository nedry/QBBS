require "tools.rb"

def putslog(output)
 writeqwklog(output)
 puts ("-QWK: #{output}")
end

 def readindex(path)
  #puts path
  index = []
 if File.exists?(path) then
 happy = File.open(path,"rb")
 happy.pos = 0
  while true
   break if happy.eof
   raw = happy.read(5)
    #print "pos: #{happy.pos} "
      #break if happy.eof
   bytes = []
   raw.each_byte {|c| bytes.push(c)}
   bytes.reverse!
   n = 0
   bytes.each {|i| n = n*256+i }
   shift=24-((n>>24) & 0x7f)
   n=(n & 0x00ffffff)  | 0x00800000
   index.push((n >>shift)-1)
  end
  
      return index
else
 puts "-QWK: NDX File not found!"
end
end

def getcontrol(path)

 list = []
 filename = "#{path}/CONTROL.DAT"
  if File.exists?(filename) then
   IO.foreach(filename) { |line| list.push(line) } 
  else 
   puts "-QWK: Invalid packet.  Control.dat not found."
   add_log_entry(8,Time.now,"Invalid QWK packet or Control.dat missing.")
  end

return list
end

def rewriteqwklog
 if File.exists?("qwklog.txt") then
  lf = File.new("qwklog.txt", File::TRUNC|File::RDWR, 0644)
  lf.close
 end 
end

def writeqwklog(line)
  
  lf = File.new("qwklog.txt", File::CREAT|File::APPEND|File::RDWR, 0644)
  lf.puts line
  lf.close
end

def getmessage(path,startrec)


 message= Message_qwk.create
 filename = "#{path}/MESSAGES.DAT"

  if File.exists?(filename) then
   happy = File.open(filename,"rb")
   
   writeqwklog ("SREC  : #{startrec}")
   happy.pos = (startrec) * 128
   message.statusflag = happy.read(1)
   message.number = happy.read(7).to_i
   writeqwklog (message.number)
   tempdate = happy.read(8)
   writeqwklog ("TDATE : #{tempdate}")
   temptime = happy.read(5)
   writeqwklog ("TTIME : #{temptime}")
   tempdatea = tempdate.split('-')
   temptimea = temptime.split(':')
   month = tempdatea[0].to_i
   day = tempdatea[1].to_i

   if tempdatea[2].to_i < 70 then 	#the start of the fucking epoc
    year = tempdatea[2].to_i + 2000
   else
    year = tempdatea[2].to_i + 1900
   end
   if (year < 1996) or (year > 2010) then year = 2000 end
   hour = temptimea[0].to_i
   min = temptimea[1].to_i
  # puts year
  # puts month
  # puts day
  # puts hour
  # puts min
   if (month == 0) or (day == 0) then message.error = true 
    else 
      message.date = Time.gm(year,month,day,hour,min) 
   end
   message.to = happy.read(25)
   writeqwklog("TO    : #{message.to}")
   message.from = happy.read(25)
   writeqwklog("FROM  : #{message.from}")
   message.subject = happy.read(25)
   writeqwklog("SUBJ  : #{message.subject}")
   message.password = happy.read(12)
   message.reference = happy.read(8).to_i
   writeqwklog("REF   : #{message.reference}")
   message.blocks = happy.read(6).to_i
   message.error = true if message.blocks == 0 
   tempcrap = happy.read(6)
   message.tagline = true if happy.read(1) == "*"
   happy.pos =(startrec + 1) * 128
   writeqwklog("BLOCKS: #{message.blocks}")
   if message.blocks > 1 then 
    temptext = happy.read((message.blocks - 1) *128)
    #temptext.each(DLIM) {|line| message.text.push(line.chop!)}
    message.text = temptext
  end
   writeqwklog("NSREC : #{startrec + message.blocks}")
   writeqwklog("")
   writeqwklog("ERROR: Corrupt packet detected.") if message.error
  else 
  # putslog("Invalid packet.  Message.dat missing!")
   message.error = true
  end

return message
end

def makearealist(list)

i = 13
num = 0
@arealist = []
num = list[10].to_i if list.length > 11
@totalareas = num
num = num * 2 + 13
if num > 0 then

 while i < num 

  temp1 = list[i].to_i
  i = i + 1
  temp2 = list[i]
  i = i + 1
  @arealist.append(Area_qwk.new(temp1,temp2))
 end
else 
 puts "-QWK: Invalid packet.  Control.dat truncated!"
end

end

 def getindexlist(path)
  list = Dir.glob(path)
  list.delete("qwk/PERSONAL.NDX") #we don't want this .. it's dupe causing
 # list.each {|x| puts x}
  return list
 end

 def printeverything
 
  i = 0
  for i in 0..(@arealist.len - 1) do
   puts "#{@arealist[i].area} #{@arealist[i].name}"
  end
 end

 def displaypacketstats
 
 writeqwklog ("#{@totalareas} areas in CONTROL.DAT")
 writeqwklog ("#{@idxlist.length} areas found in QWK packet")

  for x in 0..@idxlist.length - 1
   y = @idxlist[x].scan(/\d\d\d\d/)
   writeqwklog ("#{y} #{@arealist.findarea(y[0].to_i).name}") if @arealist.findarea(y[0].to_i) != nil
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
                      tempstr = x.to_s
                      time = tempstr.length
                       for z in 1..time do print(BS.chr) end
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



def qwkimport

 rewriteqwklog
 ddate = Time.now.strftime("%m/%d/%Y at %I:%M%p") 
  puts "-QWK: Starting import."
  add_log_entry(4,Time.now,"Starting QWK message import")
  clearoldqwk
  ftppacketdown
  unzippacket
 
 @idxlist = getindexlist("qwk/*.NDX")
 @control = getcontrol("qwk")
 makearealist (@control)
 displaypacketstats
 setitup
 
 tmsgimport = 0
 
 for pnum in 0..@idxlist.length - 1 do

   index = readindex(@idxlist[pnum])

   putslog ("Now Processing Packet #{@idxlist[pnum]} which contains #{index.length} messages.")
   writeqwklog ("")
   tempstr = @idxlist[pnum].scan(/\d\d\d\d/)
   find = tempstr[0].to_i
   puts "-QWK: Finding Import Area for packet# #{find}..."
   destnum = 0 
   destnum = find_qwk_area(find,nil) if find != 0 
   if !destnum.nil? then 
    area = fetch_area(destnum)
    putslog "Found.  Importing #{@idxlist[pnum]} to #{area.name}"
    puts
    x = 0
    boom = scanpacket(index,@idxlist[pnum])
    if !boom then 
    print "-QWK: Processing Message #" 
     
      index.each_with_index {|happy,x| 
                      #x = x.succ
		      tmsgimport = tmsgimport.succ
                      message = getmessage("qwk",happy)
		      if message.error then
		       puts
		       puts "-QWK: ERROR detected in packet.  Aborting."
		       
		       break
		      else
		       print x
		       $stdout.flush
                      tempstr = x.to_s
                      time = tempstr.length
                       for z in 1..time do print(BS.chr) end
                 
		      addmessage(message,destnum) 
		      end
		      }
      end
      else
        puts
        putslog "QWK: ERROR: No mapping found for area #{@idxlist[pnum]}"
        puts
	add_log_entry(8,Time.now,"No QWK mapping found for area #{@idxlist[pnum]}")
      end
      puts
      
     end
   add_log_entry(4,Time.now,"Import Complete. #{tmsgimport} message(s) imported.")
   puts "-QWK: import complete."
 end #of def Qwkimport
