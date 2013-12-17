class Session
  def userprofileedit
    existfileout('profilehdr',0,true)
    print "%G;Your current entry is...\r\n"
    write "%C; [1] %Y;Real Name: %W;"
    if !@c_user.real_name.nil?
      write "#{@c_user.real_name.ljust(30)}" 
    else 
      write " ".ljust(30)
    end 
    write "%C;[2] %Y;Sex:  %W;"
    write "#{@c_user.sex.ljust(5)}" if !@c_user.sex.nil?
    print " %C;[3] %Y;Age:  %W;#{@c_user.age}"
    print " %C;[4] %Y;Aliases: %W;#{@c_user.aliases}"
    print " %C;[5] %Y;City/State: %W;#{@c_user.citystate}"
    print " %C;[6] %Y;Phone #: %W;#{@c_user.voice_phone}"
    print " %C;[7] %Y;Physical Description: %W;#{@c_user.p_description}"
    print " %C;[8] %Y;Website/Email: %W;#{@c_user.url}"
    write " %C;[9] %Y;Fav. Movie: "
     if !@c_user.fav_movie.nil?
      write "%W;#{@c_user.fav_movie.ljust(30)}"
     else 
	write " ".ljust(29)
     end

    print "%C;[10] %Y;Fav TV Show: %W;#{@c_user.fav_tv}"  
    write "%C;[11] %Y;Fav Music: %W;"
    if !@c_user.fav_tv.nil? then
      write "#{@c_user.fav_music.jlust(30)}"  
    else
       write " ".ljust(30)
    end	    
    print "%C;[12] %Y;Inst Played: %W;#{@c_user.insturments}" 
    print "%C;[13] %Y;Fav. Foods: %W;#{@c_user.fav_food}" 
    print "%C;[14] %Y;Fav. Sport(s): %W;#{@c_user.fav_sport}"  
    print "%C;[15] %Y;Other Interests: %W;#{@c_user.hobbies}"  
    print "%C;[16] %Y;General Info 1: %W;#{@c_user.gen_info1}"  
    print "%C;[17] %Y;General Info 2: %W;#{@c_user.gen_info2}"  
    print "%C;[18] %Y;Summary: %W;#{@c_user.summary}"  
    print
  end

  def changerealname
    prompt = "Enter your real name (30 characters max): "
    temp =  getinp(prompt)
    if temp.length > 0 and temp.length < 31 then
      @c_user.real_name = temp
      update_user(@c_user)
      profileeditmenu
    else 
      print "%R;Your Real Name must be more than 0 characters and less than 30 characters."
    end
  end
  
  def changesex
     prompt = "What is your sex (M/F)?"
     temp =  getinp(prompt)
    if temp.upcase = "M" or temp.upcase = "F" then
      @c_user.sex = temp
      update_user(@c_user)
      profileeditmenu
    else 
      print "%R;You are either [M]ale or [F]emale so please type either M or F."
    end
  end


  def profileeditmenu
    theme = get_user_theme(@c_user) 
    userprofileedit
    prompt = theme.profileedit_prompt
    getinp(prompt) {|inp|

      if !inp.integer?
        parameters = Parse.parse(inp)
        inp.gsub!(/[-\d]/,"")
      end
      case inp.upcase
      when "1"; changerealname
      when "2"; changesex

      when "?" 
        if !existfileout('profilehdr',0,true)
	  print "User Profile:"
	  userprofileedit
        end
	
      when "1"; changerealname
      when "";	done = true
      when "Q";	done = true
      when "X";	done = true
      end
      done
    }
  end 


  def profilemenu
    theme = get_user_theme(@c_user) 
        if !existfileout('profilemenu',0,true)
	  print "User Profile:"
        end	
    prompt = theme.profile_prompt
    getinp(prompt) {|inp|

      if !inp.integer?
        parameters = Parse.parse(inp)
        inp.gsub!(/[-\d]/,"")
      end
      case inp.upcase

      when "?" 
           ogfileout('profilemenu',1,true)

      when "Y"; profileeditmenu
      when "";	done = true
      when "Q";	done = true
      when "X";	done = true
      end
      done
    }
  end 
end #class Session





