require "pty"
require "messagestrings.rb"
require 'digest/md5'

D_LIMIT = 1
D_IDLE = 5

def hex_to_base64_digest(hexdigest)
  [[hexdigest].pack("H*")].pack("m0")
end


def random_password
  return (0...8).map { (65 + rand(26)).chr }.join
end

def door_do (path,d_type)
  send_init = false
  time = Time.now
  tick = time.min.to_i
  idle = 0
  timeout = 0
  started = false
  i = 0
  ret = false
	beg = false
	u_name = @c_user.name
  user_len = u_name.length+1
	user_arr =  ">#{u_name}"
	
  begin
   
	 #make an MD5 hash in Base 64 for InterBBS userid
	 
   code = Digest::MD5.hexdigest(@c_user.name)
	 out_path = path.gsub("%uid",hex_to_base64_digest(code).slice(0..7))
	 @debuglog.push ("Door opening path - #{out_path}")

    PTY.spawn(out_path) do |read, w, p|

# w.putc(13.chr) if d_type == "DOS" #we want to put a ENTER in so dosemu won't pause at intro
      exit = false
      while !exit
        while !exit 
          ios = select([read, @socket],nil,nil,0.001) #and !exit
          r, * = ios
          if r != nil then
            if r.include?(read)
              begin
                char = read.getc
                if d_type == "RSTS" and char.chr == ":" and !send_init then
                  account = "#{RSTS_BASE},#{@c_user.rsts_acc}"
                  sleep(2)
                  w.puts(account)
                  sleep (2)
                  w.puts(@c_user.rsts_pw)
                  send_init = true
                end
                if d_type == "QBBS" and char.chr == ">" and !send_init then
                  w.puts("#{u_name}#{CR.chr}")
                  send_init = true
                end
                started = true
                idle = 0
							  beg = true if char == ">"
								if user_arr.index(char) and !ret and beg then									
								 char = ""
								 i += 1
								 ret = true if i == user_len
							 end
              rescue 
                sleep (1)
                print (CLS)
                print (HOME)

                @who.user(@c_user).where = "Main Menu"
                return
              end
              #  @socket.write CR if (char == LF) and (d_type == "DOS")
								@socket.write(char) 
            end

            if r.include?(@socket)
              char = @socket.getc
              time = Time.now
              @who.user(@c_user.name).ping =  time.to_i if !@c_user.nil?

             # if d_type == "DOS" then
             #   w.putc(char) if (char.ord != 3) and (char.ord != 27) #we want to block ctrl-c and esc
           #   else
                w.putc(char) if (char.ord !=3) and (char.ord != 0) and (char.ord != 10)

            #  end
            end
          end
        end
      end
    end 
  rescue Exception => e
 #@debuglog.push( e.backtrace.map { |x| x.match(/^(.+?):(\d+)(|:in `(.+)')$/);
  #    [$1,$2,$3]})
    return
  end


end

def door_do_mbbs (path,d_type)

  send_init = false
	
  begin
    PTY.spawn(path) do |read, w, p|

      w.putc(13.chr) if d_type == "DOS" #we want to put a ENTER in so dosemu won't pause at intro

      done = false
      temp_pass = random_password
      while !done
        while !done
          ios = select([read, @socket],nil,nil,0.001) #and !done
          r, * = ios
          if !r.nil? then
            if r.include?(read)
              begin
                char = read.getc
                if d_type == "RSTS" and char.chr == ":" and !send_init then
                  account = "#{RSTS_BASE},#{@c_user.rsts_acc}"
                  sleep(2)
                  w.puts(account)
                  sleep (2)
                  w.puts(@c_user.rsts_pw)
                  send_init = true
                end

                if d_type == "MBBS" and char.chr == ":" and !send_init then

                  if !@c_user.wg_pw.nil?  then
										sleep(2)
                    w.puts(@c_user.name)
                    w.puts(CR.chr)
										sleep(2)
                    w.puts(@c_user.wg_pw)
                    w.puts(CR.chr)
                    w.puts(CR.chr)
                  else
                    w.puts("new")
                    w.puts(CR.chr)
                    w.puts("y")
                    w.puts(CR.chr)
                    w.puts(@c_user.name)
                    w.puts(CR.chr)
                    w.puts("y")
                    w.puts(CR.chr)
										sleep(2)
                    w.puts(temp_pass)
                    w.puts(CR.chr)
										sleep(2)
                    w.puts(temp_pass)

                    w.puts(CR.chr)
                    w.puts(CR.chr)
                    @c_user.wg_pw = temp_pass
                    update_user(@c_user)
                  end
                end
								
								if d_type == "MBBS" and !send_init
									if char.chr == "|" then 
										send_init = true
									else
									case char.chr
										 when "<" 
												print "%R;Your game server account is missing!  Please tell the sysop."
												return										   
										 when "@"
		 									 print "%R;The game server is running nightly maintenance.   Please wait some time and try again."
											 return
										 when "`"
											  print "%R;Your account is already in use on the game server.  This can happen if you disconnect from the BBS"
												print "during a session without logging out.  Please wait some time and try again, or tell the sysop."
										 return
										 when "~"	
											 print "%R;Your account and password are out of sync.  Please tell sysop"
											 return
										end
								  end
								end
								
                if d_type == "QBBS" and char.chr == ">" and !send_init then
                  w.puts("#{@c_user.name}#{CR.chr}")
                  send_init = true
                end
                started = true
                idle = 0
              rescue
                @who.user(@c_user).where = "Main Menu"
                return
              end
              @socket.write CR.chr if char == LF
              @socket.write(char.chr)  if send_init
            end

            if r.include?(@socket)
              char = @socket.getc
              time = Time.now
              @who.user(@c_user.name).ping =  time.to_i if !@c_user.nil?

              if d_type == "DOS" then
                w.putc(char.chr) if (char != 3) and (char != 27) #we want to block ctrl-c and esc
              else
                w.putc(char.chr) if (char !=3) and send_init
              end
            end
          end
        end
      end
    end
  rescue

    return
  end


end

def writedoorfile(outfile)

  happy = system("rm #{outfile}")
  if happy then
    @debuglog.push("-DOOR: Deleted old door file...")
  else
    @debuglog.push("-DOOR: Failure to delete old door file")
  end

  begin
    doorfile = File.new(outfile, File::CREAT|File::APPEND|File::RDWR, 0666)
    doorfile.write("#{SYSTEMNAME}\r\n")
    sysop_out = SYSOPNAME.split
    doorfile.write("#{sysop_out[0]}\r\n")
    if sysop_out.length > 1 then
      doorfile.write("#{sysop_out[1]}\r\n")
    else
      doorfile.write("\r\n")
    end
    doorfile.write("COM0\r\n")  # always com0, as we are using telnet
    doorfile.write("0 BAUD,N,8,1\r\n") # See above
    doorfile.write("0\r\n")  #Nobody seems to know what this does
    user_out = @users.name.split
    doorfile.puts("#{user_out[0]}\r\n")
    if user_out.length > 1 then
      doorfile.write("#{user_out[1]}\r\n")
    else
      doorfile.write("\r\n")
    end
    doorfile.write("#{@users.location}\r\n")
    if @users.ansi then
      doorfile.write("1\r\n")
    else
      doorfile.write("0\r\n")
    end
    doorfile.write("#{@users.level}\r\n")
    doorfile.write("255\r\n")
    doorfile.close
  rescue
    add_log_entry(8,Time.now,"No path for door file #{outfile}")
    print "%WR;Could not write door info file... Please tell sysop.%W;"
  end
end

def showdoor(number)
  if d_total > 0 then
    door = fetch_door(number)
    print "%R;#%W;#{number} %G; #{door.name}"
    print "%C;Path:      %G;#{door.path}"
    print "%C;Type:      %G;#{door.d_type}"
    print "%C;Drop Path: %G;#{door.d_path}"
    print "%C;Drop Type: %G;#{door.droptype}"
    print "%C;Level:     %G;#{door.level}"
		print "%C;Ping Addr: %G;#{door.pingtest}"
    print
  else
    print "%WR; No Doors %W;"
  end
end

def doormaint
  readmenu(
  :initval => 1,
  :range => 1..(d_total),
  :loc => DOOR
  ) {|sel, dpointer, moved|
    if !sel.integer?
      parameters = Parse.parse(sel)
      sel.gsub!(/[-\d]/,"")
    end

    showdoor(dpointer) if moved

    case sel
    when "/"; showdoor(dpointer)
    when "Q"; dpointer = true
    when "W"; displaywho
    when "PU";page
    when "A"; adddoor
    when "P"; changedoorpath(dpointer)
    when "L"; changedoorlevel(dpointer)
    when "DP"; changedoordroppath(dpointer)
    when "DT"; changedoortype(dpointer)
    when "N"; changedoorname(dpointer)
		when "PI"; changedoorping(dpointer)
    when "K"; deletedoor(dpointer)
    when "G"; leave
    when "?"; gfileout ("doormnu")
    end # of case
    p_return = [dpointer,d_total]
  }
end

def adddoor

  name = get_max_length("Enter new Door name: ",40,"Door name")
  name.strip! if name != ""
  path = get_max_length("Enter new door path (script file): ",40,"Door path")
  path.strip! if path != ""

  if yes("Are you sure #{YESNO}", true, false,true)
    add_door(name,path,"LINUX")
  else
    print "%WR; Aborted. %W;"
  end
  print
end

def changedoorname(dpointer)
  door = fetch_door(dpointer)
  name = get_max_length("Enter new door name: ",40,"Door name")
  name.strip! if name != ""

  if name !='' then
    door.name = name
    update_door(door)
  else
    print "%WR; Not Changed. %W;"
  end
  print
end

def changedoortype(dpointer)
  door = fetch_door(dpointer)
  temp = get_max_length("Enter new door type (DOS,LINUX,RSTS,QBBS,MBBS): ",10,"Door type")
  temp.strip! if temp != ""
  door.d_type = temp.upcase if temp != nil
  update_door(door)
end

def changedoorping(dpointer)
  door = fetch_door(dpointer)
  ping = get_max_length("Enter new ping test address: ",40,"Ping Address")
 
    ping.strip!
    door.pingtest = ping

  update_door(door)
  print
end

def changedoorpath(dpointer)
  door = fetch_door(dpointer)
  print CHANGEDOORPATHWARNING
  path = get_max_length("Enter new door path (or script): ",40,"Door path")
  if path != "" then
    path.strip!
    door.path = path
  end
  update_door(door)
  print
end

def changedoordroppath(dpointer)
  print CHANGEDOORDROPPATHWARNING
  door = fetch_door(dpointer)
  d_path = get_max_length("Enter new door Drop File path: ",40,"Drop File path")
  if d_path !="" then
    d_path.strip!
    door.d_path = d_path
  end
  update_door(door)
  print
end

def changedoorlevel(dpointer)

  door = fetch_door(dpointer)
  prompt = "Enter user level required to access door: "
  area.netnum = getnum(prompt, 0, 255) || 0
  update_door(door)
  print
end

def deletedoor(dpointer)
  if dpointer > 0 then
    delete_door(dpointer)
    renumber_doors
    dpointer = d_total if dpointer > d_total
  else
    print NODOORERROR
  end
end

#-------------------Doors Section-------------------

def displaydoors
  i = 0
  existfileout("doorhdr",0,true)
  if !existfileout('door',0,true)
    if d_total < 1 then
      print "%WR; No External Programs. %W;"
      return
    end
    print "%G;Please select one of the following:"
    for i in 1..(d_total)
      door = fetch_door(i)
      write " " if i < 10
      print "    %C;#{i} %Y;... #{door.name}"
    end
    print
  end
end


def rundoor(number)
  door = fetch_door(number)
  if !door.pingtest.nil? then
		if !pingable?(door.pingtest) then
			 print "%R;External Program #{door.name} is not repsonding.  Please try again later."
			 add_log_entry(5,Time.now,"#{door.name} External program failed ping check.")
			 return
		end
	end
  if @c_user.level >= door.level then
    @who.user(@c_user.name).where = door.name
    update_who_t(@c_user.name,door.name)
    case door.droptype
    when "RBBS"; f_name = RBBSDROPFILE
    end

    node = @who.user(@c_user.name).node
    dropfile = "#{door.d_path}#{node}/#{f_name}"
    if door.d_type == "RSTS" then

      if @c_user.rsts_acc == 0 or @c_user.rsts_acc == nil then
        print "\r\nFinding a RSTS/E Account for you..."
        account = find_RSTS_account
        if account != 0 then
          @c_user.rsts_acc = account
          @c_user.rsts_pw = RSTS_DEFAULT_PSWD
          update_user(@c_user)
        else
          print "\r\n%WR;Sorry... out of accounts.  Please tell sysop!%W;"
          add_log_entry(8,Time.now,"#{@c_user.name} Out of RSTS/E Accounts Error.")
        end
      end
    end
    writedoorfile (dropfile) if door.d_type == "DOS"
    if door.d_type =="GD" then
      irc_do(door.path,door.d_type)
    else
      add_log_entry(5,Time.now,"#{@c_user.name} Ran External program #{door.name}")
      door_do(door.path,door.d_type)
    end
  else
    print "%WR;You do not have access.%W;"
  end
  @who.user(@c_user.name).where = "Main Menu"
  update_who_t(@c_user.name,"Main Menu")
end


def dlist(total)

  list = "[NONE]"
  if total > 0
    list = ""
    1.upto(total) {|i| list = list + "#{i},"}
    list.chop!
  end
  return list
end

def doors(parameters)
  theme = get_user_theme(@c_user)
  t = (parameters[0] > 0) ? parameters[0] : 0
  done = false
  if t == 0 then
    displaydoors  if !existfileout('doors',0,true)
    while true
      prompt = theme.door_prompt.gsub("@dtotal@","#{d_total}")
      prompt = prompt.gsub("@dlist@",dlist(d_total))

      getinp(prompt) {|inp|
        happy = inp.upcase
        t = happy.to_i
        case happy
        when "";   return
        when "CR"; crerror
        when @cmd_hash["doormenu"] ; run_if_ulevel("doormenu") {displaydoors}
        when @cmd_hash["doorquit"] ; run_if_ulevel("doorquit") {return}
        else
          rundoor(t) if (t) > 0 and (t) <= d_total
        end #of case
      }
    end
  end
end

