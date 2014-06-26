# TODO: clean up the blank lines

class Session

  def message_prompt(prompt,system,marea,left,nmessages,tmessages,aname,dir)
    work_prompt = nil
    work_prompt = prompt.dup if !prompt.nil?

    main_prompt = {'@sys@' => system,
      '@area@' => marea.to_s,
      '@left@' => left.to_s,
      '@new@' => nmessages.to_s,
      '@total@' => tmessages.to_s,
      '@aname@' => aname,
    '@dir@' => dir}


    if !work_prompt.nil?
      main_prompt.each_pair {|inp, result|
        work_prompt.gsub!(inp,result)
      }

    else
      work_prompt = "%WR;NO PROMPT DEFINED%W;"
    end
    return work_prompt
  end

  def prompt_help(prompt)
    print
    print "%WG;#{prompt} Prompt Parameters%W;"
    print '%G;@sys@%C;    System Name'
    print '%G;@area@%C;   Number of Current Board'
    print '%G;@aname@%C;  Name of Current Board'
    print '%G;@total@%C;  Number of Total Messages on Current Board'
    print '%G;@new@%C;    Number of New Messages on Current Board'
    print '%G;@left@%C;   Current User`s Remaining Time'
    print '%G;@name@%C;   Current User`s Name'
    if prompt == "Read" then
      print '%G;@dir@%C;    Read Direction'
      print "%G;%p%C;       Message Pointer"
    end
    print
  end

  def display_test_prompt(prompt)

    system = "Happy BBS"
    marea = "1"
    left = "10"
    nmessages = "5"
    tmessages = "60"
    aname = "General Chat"
    sdir = "+"

    "#{message_prompt(prompt,system,marea,left,nmessages,tmessages,aname,sdir)}"

  end



  def displaytheme(number)
    theme = fetch_theme(number)
    print
    print "%R;#%W;#{number} %G; #{theme.name}"
    print "%C;Description: %G;#{theme.description}"
    print "%C;Text Directory: %G;#{theme.text_directory}"
    print "%C;No Main Menu:  %W;#{theme.nomainmenu ? "On" : "Off"}"
    print "%C;Main Prompt: #{display_test_prompt(theme.main_prompt)}"
    print "%C;Read Prompt: #{display_test_prompt(theme.read_prompt)}"

  end

  def thememaint

    readmenu(
    :initval => 1,
    :range => 1..(t_total),
    :loc => THEME
    ) {|sel, tpointer, moved|
      if !sel.integer?
        parameters = Parse.parse(sel)
        sel.gsub!(/[-\d]/,"")
      end

      displaytheme(tpointer) if moved

      case sel
      when "/"; showtheme(tpointer)
      when "Q"; tpointer = true
      when "W"; displaywho
      when "PU";page
      when "A"; addtheme
      when "N"; changethemename(tpointer)
      when "RP"; changethereadprompt(tpointer)
      when "MP"; changethemainprompt(tpointer)
      when "T"; changepath(tpointer)
      when "K"; deletetheme(tpointer)
      when "G"; leave
      when "?"; gfileout ("thememnu")
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
      print "%WR;Aborted.%W;"
    end
    print
  end

  def changethemainprompt(tpointer)
    prompt_help("Main")
    theme = fetch_theme(tpointer)
    print "Current: #{theme.main_prompt}"
    prompt = getstr(true,NOWRAP,80,"Enter a new main prompt: ",false,true).strip

    if !prompt.empty? then
      theme.main_prompt = prompt
      update_theme(theme)
    else
      print "%WR;Not Changed.%W;"
    end
    print
  end


  def changethereadprompt(tpointer)
    prompt_help("Read")
    theme = fetch_theme(tpointer)
    print "Current: #{theme.read_prompt}"
    prompt = getstr(true,NOWRAP,80,"Enter a new read prompt: ",false,true).strip
    if !prompt.empty? then
      theme.read_prompt = prompt
      update_theme(theme)
    else
      print "%WR;Not Changed.%W;"
    end
    print
  end

  def changethemename(tpointer)

    theme = fetch_theme(tpointer)
    name = getinp("Enter new theme name: ")
    if !name.empty? then
      theme.name = name
      update_theme(theme)
    else
      print "%WR;Not Changed.%W;"
    end
    print
  end

  def changepath(tpointer)

    theme = fetch_theme(tpointer)
    path = getinp("Enter new text path: ")
    if !path.empty? then
      theme.text_directory = path
      update_theme(theme)
    else
      print "%WR;Not Changed.%W;"
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
      print "%WR;No themes.  That's a crash for sure.%W;"
    end
  end

  #-------------------Theme Section-------------------
  def defaulttheme
    theme = get_user_theme(@c_user)
    if theme.nil? then
      theme = fetch_theme(1) #change to get default theme
      add_theme_to_user(@c_user,theme)
    end
  end


 def displaysystems

    i = 0
    if t_total < 1 then
      print "%WR;No Themes.  That's a crash!%W;"
      return
    end
      for i in 1..(t_total)
        theme = fetch_theme(i)
        print "   #{i}...#{theme.description} (#{theme.name})"
      end
    print
  end


  def displaythemes

    i = 0
    if t_total < 1 then
      print "%WR;No Themes.  That's a crash!%W;"
      return
    end
    existfileout("themehdr",0,true)
    if !existfileout('themes',0,true)
      print "%G;Available Themes:"
      for i in 1..(t_total)
        theme = fetch_theme(i)
        print "   %B;#{i}...%G;#{theme.name}: %C;#{theme.description}"
      end
    end
    print
  end

  def themes(parameters)
    t = 0
    if !parameters.nil?
      t = (parameters[0] > 0) ? parameters[0] : 0
    end
    if t == 0 then
      displaythemes

      defaulttheme
      prompt = "\r\n%W;Theme #[1-#{t_total}] ? #{RET} to quit: "
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
              print "%WG;Setting the #{theme.name} theme.%W;"
              add_theme_to_user(@c_user,theme)
              theme = get_user_theme(@c_user)
              @cmd_hash = hash_commands(@c_user.theme_key)
              return
            end
          end #of case
        }
      end
    end
  end

end #class Session
