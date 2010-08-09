

class Session

  def displaytheme(number)
    theme = fetch_theme(number)
    print
    print "%R%#%W%#{number} %G% #{theme.name}"
    print "%C%Description: %G%#{theme.description}"
  end

  def thememaint

    readmenu(
    :initval => 1,
    :range => 1..(t_total),
    :prompt => '"%W%#{sdir}Theme [%p] (1-#{t_total}): "'
    ) {|sel, tpointer, moved|
      if !sel.integer?
        parameters = Parse.parse(sel)
        sel.gsub!(/[-\d]/,"")
      end

      displaytell(tpointer) if moved

      case sel
      when "/"; showtheme(tpointer)
      when "Q"; tpointer = true
      when "W"; displaywho
      when "PU";page
      when "A"; addtheme
      when "N"; changethemename(tpointer)
      when "K"; deletetheme(tpointer)
      when "G"; leave
      when "?"; gfileout ("bullmnu")
      end # of case
      p_return = [tpointer,(t_total)]
    }
  end

  def addtheme

    name = getinp("Enter new theme name: ",:nonempty)
    desc = getinp("Enter new theme description: ",:nonempty)

    if yes("Are you sure #{YESNO}", false, false,true)
      add_theme(name,desc)
    else
      print "%WR%Aborted.%W%"
    end
    print
  end

  def changethemename(bpointer)

    theme = fetch_theme(tpointer)
    name = getinp("Enter new theme name: ")
    if name !='' then
      theme.name = name
      update_theme(theme)
    else
      print "%WR%Not Changed.%W%"
    end
    print
  end


  def deletetheme(tpointer)
    if tpointer > 0 then
      delete_theme(tpointer)
      renumber_themes
      tpointer = t_total  if tpointer > t_total
    else
      print NOTHEMEERROR
    end
  end

  def showtheme(tpointer)
    if t_total > 0 then
      displaytheme(tpointer)
    else
      print
      print "%WR%No themes.  That's a crash for sure.%W%"
    end
  end

  #-------------------Theme Section-------------------

  def displaythemes



    i = 0
    if t_total < 1 then
      print "%WR%No Themes.  That's a crash!%W%"
      return
    end
    existfileout("themehdr",0,true)
    if !existfileout('themes',0,true)
      print "%G%Available Themes:"
      for i in 1..(t_total)
        theme = fetch_theme(i)
        print "   %B%#{i}...%G%#{theme.name}: %C%#{theme.description}"
      end
    end
    print
  end

  def themes(parameters)
    t = (parameters[0] > 0) ? parameters[0] : 0

    if t == 0 then
      displaythemes
      prompt = "\r\n%W%Theme #[1-#{t_total}] ? #{RET} to quit: "
      while true
        #  getinp(prompt, :nonempty) {|inp|    <-- removed :nonempty which prevents the loop from exiting on <return>
        getinp(prompt) {|inp|
          happy = inp.upcase
          t = happy.to_i
          case happy
          when "CR"; crerror
          when "Q" ; return
          when ""; return
          when "?";  displaythemes
          else
            if t > 0 and t <= t_total then
              theme = fetch_theme(t)
              print "%WG%Setting the #{theme.name} theme.%W%"
              add_theme_to_user(@c_user,theme)
              theme = get_user_theme(@c_user)
              print "#{theme.name} theme set."
              return
            end
          end #of case
        }
      end
    end
  end

end #class Session
