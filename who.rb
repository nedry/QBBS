require "db/db_who_telnet.rb"

class Session

  def addtowholist
    #puts "-Adding #{@c_user} to Who is Online List"
    u = @c_user
    node = find_node
    @who.append(Awho.create(u.name," ",node,u.citystate,Thread.current,u.level,"Logging On"))
    add_who_t(DB_who_T.new(false,node,u.name,u.citystate,"Logging On",""))
    return node
  end

  def find_RSTS_account

    acclist = []
    @users.each {|u|  puts(u.rsts_acc)
      if u.rsts_acc != nil then 
        if u.rsts_acc > 0 then
          acclist.push(u.rsts_acc)
        end
      end}

      for i in 1..RSTS_MAX
        break if acclist.index(i) == nil
      end 
      return i
  end

  def find_node
    nodelst = []
    @who.each {|w| nodelst.push(w.node)}

    for i in 1..NODES
      break if nodelst.index(i) == nil     
    end
    return i 
  end

  def displayirc
    i = 0
    if @irc_who.len > 0 then
      cols = %w(Y G C).map {|i| "%"+i}
      headings = %w(Node User Channel)
      widths = [5,26,20]
      header = cols.zip(headings).map {|a,b| a+b}.formatrow(widths)
      underscore = cols.zip(['-'*30]*5).map{|a,b| a+b}.formatrow(widths)
      #print header
      # print underscore
      @irc_who.each{|w|
        temp = cols.zip(["*",w.name,w.where])
        print temp.formatrow(widths)
      }
    else 

    end
    print
    print "   %Y*%R indicates an IRC user (who may also be logged in via telnet)"
    print "   %YW%R indicates an Web user (who may also be logged in via telnet)"  
    print
  end



  def displayweb
    i = 0
    if @irc_who.len > 0 then
      cols = %w(Y G C M).map {|i| "%"+i}
      headings = %w(Node User Location Where)
      widths = [5,26,20,16]
      header = cols.zip(headings).map {|a,b| a+b}.formatrow(widths)
      underscore = cols.zip(['-'*30]*5).map{|a,b| a+b}.formatrow(widths)

      fetch_who_list.each {|x|
        temp = cols.zip(["W",x[1],x[4],x[2]])
        print temp.formatrow(widths)
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
      cols = %w(Y G C M).map {|i| "%"+i}
      headings = %w(Node User Location From)
      widths = [5,26,20,16]
      header = cols.zip(headings).map {|a,b| a+b}.formatrow(widths)
      underscore = cols.zip(['-'*30]*5).map{|a,b| a+b}.formatrow(widths)
      print header
      print underscore
      @who.each_with_index {|w,i|

        temp = cols.zip([w.node, w.name, w.where, w.location])
        print temp.formatrow(widths)
      }
    else 
      print "No Users on Line.  That's fucked up, because you're on-line. Doh!" 
    end
    who_list_check
    displayweb
    displayirc 

  end
end
