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

     GraphFile.new(self, "bbsentry").profileout(fetch_bbs(absolute_bbs(number)),number)
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
