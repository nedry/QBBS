class Session

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
     print  
     abbs = fetch_bbs(absolute_bbs(number))
     write "%R;#%W;#{number} %G; #{abbs.name} %C;(%G;#{abbs.modify_date.strftime("%B %d, %Y") }%C;)"
     if abbs.imported then
       write " %WB; IMPORTED %W;" 
     else
       write " %WC; LOCAL %W;" 
     end
     write " %WY; LOCKED %W;" if abbs.locked
     print
     print "%C;Telnet:   %G;#{abbs.number}"
     write "%C;Sysop:    %G;#{abbs.sysop} " if !abbs.sysop.nil?
     write "%C;(%G;#{abbs.email}%C;)" if !abbs.email.nil?
     print
     print "%C;Location: %G;#{abbs.location} " if !abbs.location.nil?
     print "%C;Software: %G;#{abbs.software}" if !abbs.software.nil?
     if !abbs.msgs.nil? then
       write "%C;Messages: %G;#{abbs.msgs} messages"
       write "%C; in %G;#{abbs.subs} %C;message areas." if !abbs.subs.nil? 
       print
     end
    if !abbs.files.nil? then
       write "%C;Files:    %G;#{abbs.files}%C; "
       write "files in %G;#{abbs.dirs} %C;folders" if !abbs.dirs.nil? 
       write "%C; of %G;#{abbs.megs} %C;MB." if !abbs.megs.nil?
       print
     end
     print "%C;Terminal: %G;#{abbs.terminal}" if !abbs.terminal.nil?
     print "%C;Web:     %G; #{abbs.website}" if !abbs.website.nil?

     if !abbs.network.nil?
       write "%C;Network:  %G;" 
       abbs.network.split("|").each {|line| write "#{line} "}
       print
     end
     if !abbs.desc.nil?
	print
        print "%C;Description..."
        write "%W;"
        abbs.desc.split("|").each {|line| print "  #{line}"}
     end
   print
  end #displaybbslist

  def bbsmenu 
    total = bbs_total
    gfileout ("bbsmnu")
    readmenu(
      :initval => 1,
      :range => 1..(bbs_total ),
      :loc => BBS
    ) {|sel, bbspointer, moved|
      if !sel.integer?
        sel.gsub!(/[-\d+]/,"")
      end

      displaybbs(bbspointer) if moved
      case sel
        when @cmd_hash["bbsreload"] ; run_if_ulevel("bbsreload") {displaybbs(bbspointer)}      
        when @cmd_hash["bbsquit"] ; run_if_ulevel("bbsquit") {bbspointer = true}
        when @cmd_hash["bbsadd"] ; run_if_ulevel("bbsadd") {add_bbs(bbspointer)}
        when @cmd_hash["bbslock"] ; run_if_ulevel("bbslock") {lockbbs(bbspointer)}
        when @cmd_hash["bbsdelete"] ; run_if_ulevel("bbsdelete") {deletebbs(bbspointer)}
        when @cmd_hash["who"] ; run_if_ulevel("who") {displaywho}
        when @cmd_hash["page"] ; run_if_ulevel("page") {page}
	when @cmd_hash["bbscont"]; run_if_ulevel("bbscont") {fullbbslist}
        when "E"; edit_bbs(bbspointer)
        when @cmd_hash["leave"] ; run_if_ulevel("leave") {leave}
        when @cmd_hash["screenmenu"] ; run_if_ulevel("screenmenu") {gfileout ("bbsmnu")}
      end # of case
      p_return = [bbspointer,bbs_total ]

    }
  end

 
  def edit_bbs(bbspointer)
    print "Under Construction"
  end

  def add_bbs(bbspointer)
    print "Under Construction"
  end

  def deletebbs(bbspointer)
     print "Under Construction"
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
