require 'doors.rb'
require 'messagestrings.rb'



def showbbs(num)
  if o_total > 0 then
    bbs = fetch_other(num)
    print "%R;#%W%#{num} %G;#{bbs.name}"
    print "%C;Address:      %G;#{bbs.address}"
    print
  else
    print "%WR;No Other BBS Systems%W;"
  end
end

def telnetmaint
  readmenu(
  :initval => 1,
  :range => 1..(o_total),
  :loc => OTHER
  ) {|sel, bpointer, moved|
    if !sel.integer?
      parameters = Parse.parse(sel)
      sel.gsub!(/[-\d]/,"")
    end

    showbbs(bpointer) if moved

    case sel
    when "/"; showbbs(bpointer)
    when "Q"; bpointer = true
    when "W"; displaywho
    when "PU";page
    when "A"; addbbs
    when "AD"; changebbsaddress(bpointer)
    when "N"; changebbsname(bpointer)
    when "K"; deletebbs(bpointer)
    when "G"; leave
    when "?"; gfileout ("bbsmnu")
    end # of case
    p_return = [bpointer,o_total]
  }
end



def addbbs

  name = get_max_length("Enter new BBS name: ",40,"BBS name")
  name.strip! if name != ""
  address = get_max_length("Enter new BBS telnet address: ",40,"BBS address")
  address.strip! if address != ""

  if yes("Are you sure #{YESNO}", true, false,true)
    add_other(name,address)
  else
    print "%WR; Aborted. %W;"
  end
  print
end


def changebbsname(bpointer)
  bbs = fetch_other(bpointer)
  name = get_max_length("Enter new BBS name: ",40,"BBS name")
  name.strip! if name != ""

  if name !='' then
    bbs.name = name
    update_other(bbs)
  else
    print "%WR;Not Changed.%W;"
  end
  print
end

def changebbsaddress(bpointer)
  bbs = fetch_other(bpointer)
  address = get_max_length("Enter new BBS telnet address: ",40,"BBS address")
  address.strip! if address != nil

  if address !='' then
    bbs.address = address
    update_other(bbs)
  else
    print "%WR; Not Changed. %W;"
  end
  print
end

def deletebbs(bpointer)
  if bpointer > 0 then
    delete_other(bpointer)
    renumber_other
    bpointer = o_total if bpointer > o_total
  else
    print NODOORERROR
  end
end

#-------------------Doors Section-------------------

def displaybbs
  i = 0
  if o_total <= 0 then
    print "%WR; No External BBS Systems. %W;"
   else
  print "%G;Systems Available:"
  for i in 1..(o_total)
    bbs = fetch_other(i)
    print "   %B;#{i}...%G;#{bbs.name}"
  end
  end
  print
end

def runbbs(number)

  bbs = fetch_other(number)

  if @c_user.level >= bbs.level then
    @who.user(@c_user.name).where = "External BBS System"
    door_do("telnet -E #{bbs.address}","LINUX")
  else
    print "%WR; You do not have access. %W;"
  end
  @who.user(@c_user.name).where = "Main Menu"
end

def bbs(parameters)
  t = (parameters[0] > 0) ? parameters[0] : 0
  done = false
  if t == 0 then
    displaybbs if !existfileout('bbs',0,true)
    while true
      prompt = "\r\n%W;BBS #[1-#{o_total}] (?/list): #{RET} to quit:  %W;"
      getinp(prompt) {|inp|
        happy = inp.upcase
        t = happy.to_i
        case happy
        when "";   return
        when "Q"; return
        when "CR"; crerror
        when "?";  displaybbs if !existfileout('bbs',0,true)
        else
          runbbs(t) if (t) > 0 and (t) <= o_total
        end #of case
      }
    end
  end
end
