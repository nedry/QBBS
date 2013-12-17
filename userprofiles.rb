class Session

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

    GraphFile.new(self, "proedit").profileout(@c_user)
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


      when "?" ;GraphFile.new(self, "proedit").profileout(@c_user)
      when "";	done = true
      when "Q";	done = true
      when "X";	done = true
      end
      GraphFile.new(self, "proedit").profileout(@c_user) if !done
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
      when "TB"; GraphFile.new(self, "proentry").profileout(@c_user)
      when "Y"; profileeditmenu
      when "";	done = true
      when "Q";	done = true
      when "X";	done = true
      end
      done
    }
  end 
end #class Session





