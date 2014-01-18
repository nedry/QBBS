class Session


  def changebbsstring(pointer,thing,len, loop, block)
    bbs = fetch_bbs(absolute_bbs(pointer))
    prompt = "Enter #{thing} (#{len} characters max): "
    getinp(prompt) {|temp|
      if temp.length > 0 and temp.length <= len then
        block.call(temp)
        update_bbs(bbs)
        bbsmenu if !loop
        return
      else
        if !loop then
          print "%R;Not Changed!"
          return
        end
      end
    }
  end

  def addbbsstring(thing,len,req)
    prompt = "Enter #{thing} (#{len} characters max): "

    while true
      temp = getinp(prompt)
      if temp.length > 0 and temp.length <= len then
        return temp
      else
        if req then
          print "%R;Try again...%W;"
        else
          return if temp.strip.length == 0
        end
      end
    end
  end


  def addbbsnum(thing,min,max)
    prompt = "Enter #{thing}: "
    temp = getnum(prompt,min,max)
    print "temp: #{temp}"
  end

  def changebbsnum(pointer,thing,min,max, loop, block)
    bbs = fetch_bbs(absolute_bbs(pointer))
    prompt = "Enter your #{thing} (between #{min} and #{max}): "
    getinp(prompt,min,max) {|temp|
      if temp.length > 0 and temp.length <= 6 then
        block.call(temp)
        update_bbs(bbs)
        bbsmenu if !loop
        return
      else
        if !loop then
          print "%R;Not Changed!"
          return
        end
      end
    }
  end

  def fullbbslist

    i = 0
    j = 0
    temp = []
    cont = true
    if !bbs_empty  then
      cols = %w(M Y G C).map {|i| "%"+i +";"}
      hcols = %w(WM WY WG WC).map {|i| "%"+i +";"}
      headings = %w(# System Software Address)
      widths = [3,30,20,26]
      header = hcols.zip(headings).map {|a,b| a+b}.formatrow(widths) +"%W;"
      underscore = cols.zip(['-'*30]*5).map{|a,b| a+b}.formatrow(widths)

      print header
      print underscore if !@c_user.ansi

      fetch_bbs_all.each_with_index {|x,i|
        # this is kind of funky but it works.  each a/v entry can have mulitlpe network addresses seperated
        # by pipe characters.  This splits them up and puts them seperate lines.
        telnetout = x.number
        if !x.number.nil? then
          telarr = x.number.split("|")
          telnetout = telarr[0]
        end
        temp << cols.zip([i+1,x.name,x.software,telnetout]).map{|a,b| "#{a}#{b}"}.formatrow(widths) #fix for 1.9
        multiple = x.number.split("|")
        if multiple.length > 1 then
          multiple.each {|mult| temp << cols.zip(["","","",mult]).map{|a,b| "#{a}#{b}"}.formatrow(widths)}
        end
        j = j + temp.length
        if j == (@c_user.length - 2) and @c_user.more then
          cont = moreprompt
          j = 1
          if cont then
            print
            print header
            print underscore if !@c_user.ansi
          end
        end
        break if !cont
        temp.each {|t| print t}
        temp = []
      }

    else
      print "%WR; BBS List Empty %W;"
    end
  end


  def displaybbs(number)

    GraphFile.new(self, "bbsentry").profileout(fetch_bbs(absolute_bbs(number)),number) if bbs_total > 0
  end #displaybbslist

  def bbsmenu
    total = bbs_total
    gfileout ("bbsmnu")
    readmenu(
    :initval => 1,
    :range => 1..(bbs_total ),
    :loc => BBS
    ) {|sel, bbspointer, moved|


      displaybbs(bbspointer) if moved
      case sel
      when "TB"; addbbsnum("dude",0,9999999999)
      when @cmd_hash["bbsreload"] ; run_if_ulevel("bbsreload") {displaybbs(bbspointer)}
      when @cmd_hash["bbsquit"] ; run_if_ulevel("bbsquit") {bbspointer = true}
      when @cmd_hash["bbsadd"] ; run_if_ulevel("bbsadd") {add_a_bbs}
      when @cmd_hash["bbslock"] ; run_if_ulevel("bbslock") {lockbbs(bbspointer)}
      when @cmd_hash["bbsdelete"] ; run_if_ulevel("bbsdelete") {deletebbs(bbspointer)}
      when @cmd_hash["who"] ; run_if_ulevel("who") {displaywho}
      when @cmd_hash["page"] ; run_if_ulevel("page") {page}
      when @cmd_hash["bbscont"]; run_if_ulevel("bbscont") {fullbbslist}
      when @cmd_hash["leave"] ; run_if_ulevel("leave") {leave}
      when @cmd_hash["screenmenu"] ; run_if_ulevel("screenmenu") {gfileout ("bbsmnu")}
      end # of case
      p_return = [bbspointer,bbs_total ]

    }
  end


  def edit_bbs(bbspointer)
    print "Under Construction"
  end

  def add_a_bbs
    newbbs = Bbslist.new
    newbbs.user = @c_user.name
    newbbs.modify_date = Time.now
    newbbs.name = addbbsstring("the name of the BBS system",30,true)
    newbbs.sysop = addbbsstring("the sysop's name",30,false)
    newbbs.location = addbbsstring("the system's location",30,false)
    newbbs.software = addbbsstring("the BBS software",30,false)
    newbbs.number = addbbsstring("the BBS telnet address",30,true)
    newbbs.website = addbbsstring("the BBS http address",30,false)
    newbbs.network = addbbsstring("the message networks, seperated by | characters\r\n",80,false)
    temp = addbbsnum("the number of messages:",0,999999999)
    newbbs.msgs = temp if !temp.nil?
    temp = addbbsnum("the number of message areas",0,999999999)
    newbbs.subs = temp if !temp.nil?
    temp = addbbsnum("the number of files",0,999999999)
    newbbs.files = temp if !temp.nil?
    temp = addbbsnum("the number of file directories",0,999999999)
    newbbs.dirs = temp if !temp.nil?
    newbbs.terminal = addbbsstring("the supported terminal types",80,false)
    saveit,title = lineedit( :maxsize => 5, :header => "%G;Enter a description of this system.%Y;")
    newbbs.desc = @lineeditor.msgtext.join("|") if @lineeditor.msgtext.length > 0
    newbbs.save if yes("\nAdd BBS (you may edit it later if you've made a mistake)? #{YESNO}",true,false,true)
  end

  def deletebbs(bbspointer)
    delete_bbs_pointer(bbspointer)
    print "BBS ##{bbspointer} deleted..."
  end

  def lockbbs(bbspointer)
    abbs =  fetch_bbs(absolute_bbs(bbspointer))
    if abbs.locked then
      abbs.locked = false
      print "%WG;BBS ##{bbspointer} UNlocked%W;"
    else
      abbs.locked = true
      print "%WR;BBS ##{bbspointer} locked.%W;"
    end
    update_bbs(abbs)
  end


end #class Session
