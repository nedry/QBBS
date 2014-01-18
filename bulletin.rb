require "messagestrings.rb"

class Session

  def displaybull(number)
    bulletin = fetch_bulletin(number)
    print
    print "%R;#%W;#{number} %G; #{bulletin.name}"
    print "%C;Path: %G;#{bulletin.path}"
  end

  def bullmaint

    readmenu(
    :initval => 1,
    :range => 1..(b_total),
    :loc => BULLETIN
    ) {|sel, bpointer, moved|
      if !sel.integer?
        parameters = Parse.parse(sel)
        sel.gsub!(/[-\d]/,"")
      end

      displaybull(bpointer) if moved

      case sel
      when "/"; showbulletin(bpointer)
      when "Q"; bpointer = true
      when "W"; displaywho
      when "PU";page
      when "A"; addbulletin
      when "C"; createbulletin
      when "E"; editbulletinname(bpointer)
      when "P"; changebulletinpath(bpointer)
      when "N"; changebulletinname(bpointer)
      when "K"; deletebulletin(bpointer)
      when "G"; leave
      when "?"; gfileout ("bullmnu")
      end # of case
      p_return = [bpointer,(b_total)]
    }
  end

  def addbulletin

    name = getinp("Enter new bulletin name: ",:nonempty)
    path = getinp("Enter new bulletin filename (without extension): ",:nonempty)
    if yes("Are you sure #{YESNO}", true, false,true)
      add_bulletin(name, path)
    else
      print "%WR; Aborted. %W;"
    end
    print
  end

  def writefromlineeditor(file)

    File.open(file, "w") do |f|
      @lineeditor.msgtext.each {|line| f.write "#{line}\n" }
    end
  end

  def invokeeditor(path,edit)
    if @c_user.fullscreen then
      launch = FULLSCREENPROG
      launch.gsub!("%a","#{ROOT_PATH}#{TEXT_PATH}")
      print (CLS)
      print (HOME)
      sleep(1)
      door_do("#{launch} #{ROOT_PATH}#{TEXT_PATH}#{path}.txt","")
    else
      file = nil
      file = "#{ROOT_PATH}#{TEXT_PATH}#{path}.txt" if edit
      saveit = lineedit(1,"",file,nil)
      if saveit then
        writefromlineeditor("#{ROOT_PATH}#{TEXT_PATH}#{path}.txt")
      end
    end

  end

  def editbulletinname(bpointer)

    bulletin = fetch_bulletin(bpointer)
    if yes("Are you sure #{YESNO}", true, false,true)
      invokeeditor(bulletin.path,true)
    end
    print
  end

  def createbulletin

    name = getinp("Enter new bulletin name: ",:nonempty)
    path = getinp("Enter new bulletin filename (without extension): ",:nonempty)
    invokeeditor(path,false)
    if yes("Are you sure #{YESNO}", true, false,true)
      add_bulletin(name, path)
    else
      print "%WR; Aborted. %W;"
    end
    print
  end


  def changebulletinname(bpointer)

    bulletin = fetch_bulletin(bpointer)
    name = getinp("Enter new bulletin name: ")
    if name !='' then
      bulletin.name = name
      update_bulletin(bulletin)
    else
      print "%WR;Not Changed.%W;"
    end
    print
  end

  def changebulletinpath(bpointer)

    bulletin = fetch_bulletin(bpointer)
    print CHANGEBULLETINPATHWARNING
    path = getinp("Enter new bulletin filename (no extension): ")
    if path != ""
      bulletin.path = path
      update_bulletin(bulletin)
      print
    else
      print "%WR; Not Changed. %W;"
    end
  end

  def deletebulletin(bpointer)
    if bpointer > 0 then
      delete_bulletin(bpointer)
      renumber_bulletins
      bpointer = b_total  if bpointer > b_total
    else
      print NOBULLETINERROR
    end
  end

  def showbulletin(bpointer)
    if b_total > 0 then
      displaybull(bpointer)
    else
      print
      print "%WR; No bulletins.  Why not add one? %W;"
    end
  end

  #-------------------Bulletin Section-------------------

  def displaybullet



    i = 0
    if b_total < 1 then
      print "%WR; No Bulletins %W;"
      return
    end
    existfileout("bullethdr",0,true)
    if !existfileout('bulletins',0,true)
      print "%G;Please select one of the following:"
      for i in 1..(b_total)
        bulletin = fetch_bulletin(i)
        print "   %C;#{i} %Y;... #{bulletin.name}"
      end
    end
    print
  end

  def bullets(parameters)
    theme = get_user_theme(@c_user)
    t = (parameters[0] > 0) ? parameters[0] : 0

    if t == 0 then
      displaybullet  if !existfileout('bulletins',0,true)
      prompt = theme.bull_prompt.gsub("@btotal@","#{b_total}")
      prompt = prompt.gsub("@blist@",dlist(b_total))
      while true
        getinp(prompt) {|inp|
          happy = inp.upcase
          t = happy.to_i
          case happy
          when "CR"; crerror
          when @cmd_hash["bullquit"] ; run_if_ulevel("bullquit") {return}
          when @cmd_hash["bullmenu"] ; run_if_ulevel("bullmenu") {displaybullet}
          when ""; return
          else
            if t > 0 and t <= b_total then
              bulletin = fetch_bulletin(t)
              ogfileout(bulletin.path,1,true) #if @bulletins.has_index?(t)
            end
          end #of case
        }
      end
    end
  end

end #class Session
