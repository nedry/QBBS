require "db/db_who_telnet.rb"

class Session

  def addtowholist
    @debuglog.push("-SA: Adding #{@c_user.name} to the Who is Online List")
    u = @c_user
    node = find_node
    @who.append(Awho.create(u.name," ",node,u.citystate,Thread.current,u.level,"Logging On",u.sex))
    add_who_t(false,node,u.citystate,"Logging On",u.name)
    return node
  end

  def find_free(list, max)
    (1..max).detect(max) {|i| list.index(i) == nil }
  end

  def find_node
    nodelst = @who.map {|w| w.node}
    find_free(nodelst, NODES)
  end

  def displayirc
    i = 0
    if @irc_who.len > 0 then
      cols = %w(Y G C).map {|i| "%"+i +";"}
      hcols = %w(YW GW CW).map {|i| "%"+i +";"}
      headings = %w(Node User Channel)
      widths = [4,15,21]
      header = hcols.zip(headings).map {|a,b| a+b}.formatrow(widths)
      underscore = cols.zip(['-'*30]*5).map{|a,b| a+b}.formatrow(widths)
      @irc_who.each{|w|
        print cols.zip(["*",w.name,w.where.strip]).map{|a,b| "#{a}#{b}"}.formatrow(widths)
      }
    else

    end
    print
    print "   %Y;*%R; = IRC user (who may also be logged in via telnet).  %Y;W%R; = Web user."
    print
  end

  def displayweb
    i = 0
    if w_total > 0 then
      cols = %w(Y G C M).map {|i| "%"+i + ";" }
      headings = %w(Node User Location Where)
      widths = [4,15,21,16]
      header = cols.zip(headings).map {|a,b| a+b}.formatrow(widths)
      underscore = cols.zip(['-'*30]*5).map{|a,b| a+b}.formatrow(widths)

      fetch_who_list.each {|x|
        print cols.zip(["W",x.user.name,x.place,x.user.citystate]).map{|a,b| "#{a}#{b}"}.formatrow(widths)
      }
addtowholist
    end
  end

  def displaywho
    i = 0
    if @who.len > 0 then
      if !existfileout('whobanner',0,true)
        print "Telnet Users Online:"
        print
     end

      cols = %w(Y G C M M M B).map {|i| "%"+i +";"}
       hcols = %w(WY WG WC  WM WM WM WB).map {|i| "%"+i +";"}
      headings = %w(LN User Module S Min Class Location)
      widths = [4,15,21,2,4,10,15]
      
      if !existfileout('whohdr',0,true)
        header = hcols.zip(headings).map {|a,b| a+b}.formatrow(widths) + "%W;"
        test= cols.zip(headings).map {|a,b| a+b}
        print header
        print if !@c_user.ansi
      end
      @who.each_with_index {|w,i|

	user = "USER"
	user = "STAFF" if w.level = 255 
	tme = (Time.now - w.date) / 60
	
        print cols.zip([w.node, w.name, w.where, w.sex, tme.to_i, user , w.location]).map{|a,b| "#{a}#{b}"}.formatrow(widths)
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
