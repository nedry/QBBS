require "db/db_who_telnet.rb"

class Session

  def addtowholist
    puts "-Adding #{@c_user} to Who is Online List"
    u = @c_user
    node = find_node
    @who.append(Awho.create(u.name," ",node,u.citystate,Thread.current,u.level,"Logging On"))
    add_who_t(false,node,u.citystate,"Logging On",u.name)
    return node
  end

  def find_free(list, max)
    (1..max).detect(max) {|i| list.index(i) == nil }
  end

  def find_RSTS_account
    acclist = @users.map {|u| u.rsts_acc}.compact.select {|r| r > 0}
    find_free(acclist, RSTS_MAX)
  end

  def find_node
    nodelst = @who.map {|w| w.node}
    find_free(nodelst, NODES)
  end

  def displayirc
    i = 0
    if @irc_who.len > 0 then
      cols = %w(Y G C).map {|i| "%"+i +"%"}
      headings = %w(Node User Channel)
      widths = [5,26,20]
      header = hcols.zip(headings).map {|a,b| a+b}.formatrow(widths)
      underscore = cols.zip(['-'*30]*5).map{|a,b| a+b}.formatrow(widths)
      @irc_who.each{|w|
        print cols.zip(["*",w.name,w.where]).map{|a,b| "#{a}#{b}"}.formatrow(widths)
      }
    else

    end
    print
    print "   %Y%*%R% = IRC user (who may also be logged in via telnet).  %Y%W%R% = Web user."
    print
  end

  def displayweb
    i = 0
    if w_total > 0 then
      cols = %w(Y G C M).map {|i| "%"+i + "%" }
      headings = %w(Node User Location Where)
      widths = [5,26,20,16]
      header = cols.zip(headings).map {|a,b| a+b}.formatrow(widths)
      underscore = cols.zip(['-'*30]*5).map{|a,b| a+b}.formatrow(widths)

      fetch_who_list.each {|x|
        print cols.zip(["W",x.user.name,x.place,x.user.citystate]).map{|a,b| "#{a}#{b}"}.formatrow(widths)
      }

    end
  end

  def displaywho
    i = 0
    if @who.len > 0 then
      if !existfileout('whobanner',0,true)
        print "Telnet Users Online:"
        print
      end
      cols = %w(Y G C M).map {|i| "%"+i +"%"}
      hcols = %w(WY WG WC WM).map {|i| "%"+i +"%"}
      headings = %w(Node User Location From)
      widths = [5,26,20,16]
      header = hcols.zip(headings).map {|a,b| a+b}.formatrow(widths) + "%W%"
      test= cols.zip(headings).map {|a,b| a+b}
      underscore = cols.zip(['-'*30]*5).map{|a,b| a+b}.formatrow(widths)
      print header
      print underscore if !@c_user.ansi
      @who.each_with_index {|w,i|
        print cols.zip([w.node, w.name, w.where, w.location]).map{|a,b| "#{a}#{b}"}.formatrow(widths)
      }
    else
      print "No Users on Line.  That's fucked up, because you're on-line. Doh!"
    end
    who_list_check
    displayweb
    displayirc
    print""
  end
end
