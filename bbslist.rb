class Session

  def fullbbslist 
    print "Under Construction"
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
      when "/"; displaybbs(bbspointer)
      when "Q"; bbspointer = true
      when "A"; add_bbs(bbspointer)
      when "L"; lockbbs(bbspointer)
      when "K"; deletebbs(bbspointer)
      when "W"; displaywho
      when "PU"; page    
      when "E"; edit_bbs(bbspointer)
      when "G"; leave
      when "?"; gfileout ("usermnu")
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
