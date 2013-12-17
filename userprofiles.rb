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
      write "%W;#{@c_user.fav_movie.ljust(29)}"
     else 
	write " ".ljust(29)
     end

    print "%C;[10] %Y;Fav TV Show: %W;#{@c_user.fav_tv}"  
    write "%C;[11] %Y;Fav Music: %W;"
    if !@c_user.fav_music.nil? then
      write "#{@c_user.fav_music.jlust(29)}"  
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

 

   def changeuserstring(thing,len, block)
    prompt = "Enter #{thing} (#{len} characters max): "
    temp =  getinp(prompt)
    if temp.length > 0 and temp.length <= len then
      block.call(temp)
      update_user(@c_user)
      profileeditmenu
    else 
      print "%R;Not Changed!"
    end
  end
  
  def changeusernum(thing,min,max, block)
    prompt = "Enter your #{thing} (between #{min} and #{max}): "
    temp =  getinp(prompt,min,max)
    if temp.length > 0 and temp.length <= 6 then
      block.call(temp)
      update_user(@c_user)
    else 
      print "%R;Not Changed"
    end
  end
  
  def changesex
     prompt = "What is your sex (M/F)?"
     temp =  getinp(prompt)
    if temp.upcase == "M" or temp.upcase == "F" then
      @c_user.sex = temp.upcase
      update_user(@c_user)
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
      when "1"; changeuserstring("real name",30, Proc.new{|temp| @c_user.real_name = temp})
      when "2"; changesex
      when "3"; changeusernum("age",0,130,Proc.new{|temp| @c_user.age = temp}) 
      when "4"; changeuserstring("aliases",30, Proc.new{|temp| @c_user.aliases = temp})
      when "5"; changeuserstring("city and state",30, Proc.new{|temp| @c_user.citystate = temp})
      when "6"; changeuserstring("phone number (or none)",30, Proc.new{|temp| @c_user.voice_phone = temp})
      when "7"; changeuserstring("physical description",30, Proc.new{|temp| @c_user.p_description = temp})
      when "8"; changeuserstring("website and/or email address",30, Proc.new{|temp| @c_user.url = temp})
      when "9"; changeuserstring("favorite movie(s)",30, Proc.new{|temp| @c_user.fav_movie = temp})
      when "10"; changeuserstring("favorite tv show(s)",30, Proc.new{|temp| @c_user.fav_tv = temp})
      when "11"; changeuserstring("favorite music",30, Proc.new{|temp| @c_user.fav_music = temp})
      when "12"; changeuserstring("instruments you play (if any)",30, Proc.new{|temp| @c_user.insturments = temp})
      when "13"; changeuserstring("favourite food(s)",30, Proc.new{|temp| @c_user.fav_food = temp})
      when "14"; changeuserstring("favourite sports(s)",30, Proc.new{|temp| @c_user.fav_sport = temp})
      when "15"; changeuserstring("interests or hobbies",30, Proc.new{|temp| @c_user.hobbies = temp})
      when "16"; changeuserstring("any other info (line 1)",70, Proc.new{|temp| @c_user.gen_info1 = temp})
      when "17"; changeuserstring("any other info (line 2)",70, Proc.new{|temp| @c_user.gen_info2 = temp})
      when "18"; changeuserstring("summary",50, Proc.new{|temp| @c_user.summary = temp})


      when "?" 
        if !existfileout('profilehdr',0,true)
	  print "User Profile:"
	  userprofileedit
        end
	
      when "";	done = true
      when "Q";	done = true
      when "X";	done = true
      end
      profileeditmenu if !done
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





