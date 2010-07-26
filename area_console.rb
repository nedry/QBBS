require 'db/db_area'

class AreaConsole
  def areamaintmenu
    readmenu(
      :initval => 0,
      :range => 0..(a_total - 1),
      :prompt => '"%W#{sdir} Area [%p] (0-#{a_total - 1}): "'
    ) {|sel, apointer, moved|
      displayarea(apointer) if moved
      case sel
      when "/"; displayarea(apointer)
      when "Q"; apointer = true
      when "A"; apointer = addarea
      when "NN"; changeqwkrep(apointer)
      when "FN"; changefidoarea(apointer)
      when "CF"; clearfidoarea(apointer)
      when "W"; displaywho
      when "PU"; page
      when "N"; changeareaname(apointer)
      when "D"; changedefaultaccess(apointer)
      when "V"; changevalidatedaccess(apointer)
      when "K"; deletearea(apointer)
      when "S"; lockarea(apointer)
      when "G"; leave
      when "CG"; changegroup(apointer)
      when "?"; gfileout ("areamnu")
      end # of case
      p_return = [apointer,(a_total - 1)]
    }
  end

  def display_list
    cont = false
    user = @session.c_user
    more = 0
    grp = select_message_group
    area_list = fetch_area_list(grp)

    print
    display_header
    area_list.each_with_index do |area, i|
      pointer = get_pointer(user, area.number)
      if (pointer.access != "I") or (user.level == 255) and (!area.delete) then
        more += 1
        display_new_messages(area, pointer)
      end

      prompt = "%WMore #{YESNO} or Area #? "
      if more > 19 then
        cont = yes_num(prompt,true,true)
        more = 0
        break if !cont or cont.kind_of?(Fixnum)
      end
    end
    
    return cont
  end

  def displayarea(number)
    area = fetch_area(number)
    write "\r\n%R#%W#{number} %G #{area.name}"
    write "%R [DELETED]" if area.delete
    write "%R [LOCKED]" if area.locked
    print ""
    if area.netnum > -1 then
      out = area.netnum
    else
      out = "NONE"
    end

    print <<-here
%CDefault Access: %G#{area.d_access}
%CValidated Access: %G#{area.v_access}
%CQWK/REP Net # %G#{out}
%CFidoNet Area: %G#{area.fido_net}
%CLast Modified: %G#{area.modify_date}
%CTotal Messages: %G#{m_total(area.number)}
%CGroup: %G#{area.group.groupname}
here

  end #displayarea

  def deletearea(apointer)
    if apointer <= 1
      print "%RYou cannot delete area 0 or 1."
      return
    end

    area = fetch_area(apointer)

    if area.delete
      area.delete = false
      print "Area ##{apointer} UNdeleted"
    else
      area.delete = true
      print "Area ##{apointer} deleted."
    end
    update_area(area)
  end

  def lockarea(apointer)
    area = fetch_area(apointer)

    if area.locked then
      area.locked = false
      print "Area ##{apointer} UNlocked"
    else
      area.locked = true
      print "Area ##{apointer} locked."
    end
    update_area(area)
  end

  def changevalidatedaccess(apointer)
    area = fetch_area(apointer)

    prompt = "Enter new validated access level for board #{apointer}: "
    tempstr2 = getinp(prompt).upcase
    if tempstr2 =~ /[NIWRMC]/
      area.v_access = tempstr2
      print "Board #{apointer} validated access changed to #{tempstr2}"
      update_area(area)
    else
      print "%RInvalid Selection"
    end
  end

  def changegroup(apointer)
    area = fetch_area(apointer)
    groups = fetch_groups
    print
    print "Select New Group #"
    groups.each_index {|j| print "#{j}: #{groups[j].groupname}"}
    prompt = "Enter new group number for board #{apointer}: "
    tempint = getnum(prompt,0,groups.length - 1)
    area.grp = groups[tempint].grp
    update_group(area)
    print "Area Updated"
  end

  def changedefaultaccess(apointer)
    area = fetch_area(apointer)

    prompt = "Enter new default access level for board #{apointer}: "
    tempstr2 = getinp(prompt).upcase
    if tempstr2 =~ /[NIWRMC]/
      area.d_access = tempstr2
      print "Board #{apointer} default access changed to #{tempstr2}"
      update_area(area)
    else
      print "%RInvalid Selection"
    end
  end

  def addarea
    print ADDAREAWARNING
    while true
      prompt = "Enter new area name: "
      name = getinp(prompt) {|n| n != ""}
      if name.length > 40 then
        print "%RName too long. 40 Character Maximum"
      else break end
    end

    commit = yes("Are you sure #{YESNO}",true,false,true)
    if commit then
      add_area(name,"W","W",nil,nil,nil)
      apointer = a_total - 1
    else
      print "%RCancelled."
      apointer = a_total - 1
      return
    end
  end

  def changeqwkrep(apointer)
    area = fetch_area(apointer)

    print QWKREPWARNING

    while true
      prompt = "Enter new QWK/REP number (N / no mapping): "
      netnum = getinp(prompt) {|n| n != ""}
      if netnum =="N" or netnum == "n"
        area.netnum = -1
        break
      end
      if netnum.to_i > -1 and netnum.to_i < 10000 then
        area.netnum = netnum.to_i
        break
      end
    end
    update_area(area)
    print
  end

  def changeareaname(apointer)
    area = fetch_area(apointer)

    while true
      prompt = "Enter new area name: "
      name = getinp(prompt) {|n| n != ""}
      if name.length > 40 then
        print "Name too long. 40 Character Maximum"
      else break end
    end
    area.name = name
    update_area(area)
    print
  end

  def changefidoarea(apointer)
    area = fetch_area(apointer)

    while true
      prompt = "Enter new FidoNet Area Mapping: "
      fido_net= getinp(prompt) {|n| n != ""}
      if fido_net.length > 40 then
        print "Area too long. 40 Character Maximum"
      else break end
    end
    area.fido_net = fido_net.upcase
    update_area(area)
  end

  def clearfidoarea(apointer)
    area = fetch_area(apointer)
    commit = yes("Clear Fidonet Area Mapping. Are you sure #{YESNO}",false,false,true)

    if commit then
      area.fido_net = nil
      update_area(area)
      print
      print "Cleared Fido Mapping"
    else
      print
      print "Not Cleared."
    end
  end
end
