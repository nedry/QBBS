
require "messagestrings.rb"


def showscreen(number)
  if s_total > 0 then 
    screen = fetch_screen(number)
    print "%R;#%W;#{number} %G; #{screen.name}"
    print "%C;Path:      %G;#{screen.path}"
    print "%C;Type:      %G;#{screen.d_type}"
    print "%C;Drop Path: %G;#{screen.d_path}"
    print "%C;Drop Type: %G;#{screen.droptype}"
    print
  else 
    print "%WR;No Screen Savers%W;"
  end
end

def screenmaint
  readmenu(
    :initval => 1,
    :range => 1..(s_total),
    :loc => SCREEN
  ) {|sel, spointer, moved|
    if !sel.integer?
      parameters = Parse.parse(sel)
      sel.gsub!(/[-\d]/,"")
    end

    showscreen(spointer) if moved

    case sel
    when "/"; showscreen(spointer)
    when "Q"; spointer = true
    when "W"; displaywho
    when "PU";page
    when "A"; addscreen
    when "P"; changescreenpath(spointer)
    when "DP"; changescreendroppath(spointer)
    when "DT"; changescreentype(spointer)
    when "N"; changescreenname(spointer)
    when "K"; deletescreen(spointer)
    when "G"; leave
    when "?"; gfileout ("screenmnu")
    end # of case
    p_return = [spointer,s_total]
  }
end

def addscreen

  name = get_max_length("Enter new Screensaver name: ",40,"Door name")
  name.strip! if name != ""
  path = get_max_length("Enter new Screensaver path (script file): ",40,"Screensaver path") 
  path.strip! if path != ""

  if yes("Are you sure #{YESNO}", false, false,true)
    add_screen(name,path)
  else
    print "%WR;Aborted.%W;"
  end
  print
end

def changescreenname(dpointer)
  screen = fetch_screen(spointer)
  name = get_max_length("Enter new Screensaver name: ",40,"Screensaver name") 
  name.strip! if name != ""

  if name !='' then
    screen.name = name
    update_screen(screen)
  else
    print "%WR;Not Changed.%W;"
  end
  print
end

def changescreentype(spointer)
  screen = fetch_screen(spointer)
  temp = get_max_length("Enter new Screensaver type (DOS,LINUX,RSTS): ",10,"Screensaver type") 
  temp.strip! if temp != ""
  screen.d_type = temp.upcase if temp != nil
  update_screen(screen)
end



def changescreenpath(spointer)
  screen = fetch_screen(spointer)
  print CHANGEDOORPATHWARNING
  path = get_max_length("Enter new Screensaver path (or script): ",40,"Screensaver path")
  if path != "" then
    path.strip!
    screen.path = path
  end
  update_door(door)
  print
end

def changescreendroppath(spointer)
  print CHANGEDOORDROPPATHWARNING
  screen = fetch_screen(spointer)
  d_path = get_max_length("Enter new door Drop File path: ",40,"Drop File path")
  if d_path !="" then
    d_path.strip!
    screen.d_path = d_path 
  end
  update_screen(screen)
  print
end


def deletescreen(spointer)
  if spointer > 0 then
    delete_screen(spointer)
    renumber_screens
    spointer = s_total if spointer > s_total
  else
    print NODOORERROR
  end
end

#-------------------Doors Section-------------------

def displayscreens
  i = 0
  existfileout("screenhdr",0,true)
  if !existfileout('screen',0,true)
  if s_total < 1 then
    print "%WR;No Screensavers.  Sorry!.%W;"
    return
  end
  print "%G;Screensavers Available:"
  for i in 1..(s_total)
    screen = fetch_screen(i)
    print "   %B;#{i}...%G;#{screen.name}"
  end
    print "   %B;N...%G;No Screen Savers"
   print
  end
end




def screensaver(parameters)
  t = (parameters[0] > 0) ? parameters[0] : 0
  done = false
  if t == 0 then
    displayscreens  if !existfileout('screens',0,true)
    while true
      prompt = "\r\n%W;Screensaver #[1-#{s_total}] ? #{RET} to quit: "
      getinp(prompt) {|inp|
        happy = inp.upcase
        t = happy.to_i
        case happy
        when "";   return
        when "CR"; crerror
        when "N"; clear_screen(@c_user)
        when @cmd_hash["screenmenu"] ; run_if_ulevel("screenmenu") {displayscreens}
        when @cmd_hash["screenquit"] ; run_if_ulevel("screenmenu") {return}
        else
               if t > 0 and t <= t_total then
              screen = fetch_screen(t)
              print "%WG;Setting the #{screen.name} Screensaver.%W;"
              add_screen_to_user(@c_user,screen)            
              return
            end
        end #of case
      }
    end
  end
end

