class Session
	     include Comparable

   def changeuserstring(thing,len, loop, block)
    prompt = "Enter #{thing} (#{len} characters max): "
    getinp(prompt) {|temp|
    if temp.length > 0 and temp.length <= len then
      block.call(temp)
      update_user(@c_user)
       profileeditmenu if !loop 
       return
    else 
      if !loop then
        print "%R;Not Changed!"
        return 
       end
    end
    }
  end
  
  def changeusernum(thing,min,max, loop, block)
    prompt = "Enter your #{thing} (between #{min} and #{max}): "
   getinp(prompt,min,max) {|temp|
    if temp.length > 0 and temp.length <= 6 then
      block.call(temp)
      update_user(@c_user)
      profileeditmenu if !loop 
      return
    else 
       if !loop then
          print "%R;Not Changed!"
          return 
       end
     end
   }
  end
  
  def changesex(loop)
     prompt = "What is your sex (M/F)?"
     getinp(prompt) {|temp|
    if temp.upcase == "M" or temp.upcase == "F" then
      @c_user.sex = temp.upcase
      update_user(@c_user)
      profileeditmenu if !loop
      return
    else 
       print "%R;You are either [M]ale or [F]emale so please type either M or F."
       return if !loop 
      end
    }
  end

  def profileadd
      changeuserstring("real name",30, true, Proc.new{|temp| @c_user.real_name = temp})
      changesex(true)
      changeusernum("your age",0,130,true,Proc.new{|temp| @c_user.age = temp}) 
      changeuserstring("your aliases",30,true, Proc.new{|temp| @c_user.aliases = temp})
      changeuserstring("your city and state",30, true, Proc.new{|temp| @c_user.citystate = temp})
      changeuserstring("your phone number (or none)",30,true, Proc.new{|temp| @c_user.voice_phone = temp})
      changeuserstring("your physical description",30,true, Proc.new{|temp| @c_user.p_description = temp})
      changeuserstring("your website and/or email address",30,true, Proc.new{|temp| @c_user.url = temp})
      changeuserstring("your favorite movie(s)",30,true, Proc.new{|temp| @c_user.fav_movie = temp})
      changeuserstring("your favorite tv show(s)",30,true, Proc.new{|temp| @c_user.fav_tv = temp})
      changeuserstring("your favorite music",30,true, Proc.new{|temp| @c_user.fav_music = temp})
      changeuserstring("your instruments you play (if any)",30,true, Proc.new{|temp| @c_user.insturments = temp})
      changeuserstring("your favourite food(s)",30, true, Proc.new{|temp| @c_user.fav_food = temp})
      changeuserstring("your favourite sports(s)",30, true, Proc.new{|temp| @c_user.fav_sport = temp})
      changeuserstring("your interests or hobbies",30, true,Proc.new{|temp| @c_user.hobbies = temp})
      changeuserstring("any other info (line 1)",70, true,Proc.new{|temp| @c_user.gen_info1 = temp})
      changeuserstring("any other info (line 2)",70, true,Proc.new{|temp| @c_user.gen_info2 = temp})
      changeuserstring("your summary",50, true,Proc.new{|temp| @c_user.summary = temp})
      @c_user.profile_added = true
      update_user(@c_user)
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
      when "1"; changeuserstring("your real name",30, false, Proc.new{|temp| @c_user.real_name = temp})
      when "2"; changesex(false)
      when "3"; changeusernum("your age",0,130,false,Proc.new{|temp| @c_user.age = temp}) 
      when "4"; changeuserstring("your aliases",30,false, Proc.new{|temp| @c_user.aliases = temp})
      when "5"; changeuserstring("your city and state",30, false,Proc.new{|temp| @c_user.citystate = temp})
      when "6"; changeuserstring("your phone number (or none)",30,false, Proc.new{|temp| @c_user.voice_phone = temp})
      when "7"; changeuserstring("your physical description",30,false, Proc.new{|temp| @c_user.p_description = temp})
      when "8"; changeuserstring("your website and/or email address",30, true,Proc.new{|temp| @c_user.url = temp})
      when "9"; changeuserstring("your favorite movie(s)",30,false, Proc.new{|temp| @c_user.fav_movie = temp})
      when "10"; changeuserstring("your favorite tv show(s)",30,false, Proc.new{|temp| @c_user.fav_tv = temp})
      when "11"; changeuserstring("your favorite music",30,false, Proc.new{|temp| @c_user.fav_music = temp})
      when "12"; changeuserstring("your instruments you play (if any)",30,false, Proc.new{|temp| @c_user.insturments = temp})
      when "13"; changeuserstring("your favourite food(s)",30, false, Proc.new{|temp| @c_user.fav_food = temp})
      when "14"; changeuserstring("your favourite sports(s)",30, false, Proc.new{|temp| @c_user.fav_sport = temp})
      when "15"; changeuserstring("your interests or hobbies",30, false,Proc.new{|temp| @c_user.hobbies = temp})
      when "16"; changeuserstring("any other info (line 1)",70, false,Proc.new{|temp| @c_user.gen_info1 = temp})
      when "17"; changeuserstring("any other info (line 2)",70, false,Proc.new{|temp| @c_user.gen_info2 = temp})
      when "18"; changeuserstring("your summary",50, false,Proc.new{|temp| @c_user.summary = temp})


      when "?" ;GraphFile.new(self, "proedit").profileout(@c_user)
      when "";	done = true
      when "Q";	done = true
      when "X";	done = true
      end
      GraphFile.new(self, "proedit").profileout(@c_user) if !done
      done
    }
  end 

  def alpha_list(startchar)
    j = 1
    cont = true
    nomore = false
    nonstop = false

     list = fetch_profile_list
     print "%G;USER-ID                             ... SUMMARY"
     print "-----------------------------------------------"
     list.each {|i| 
             j = j + 1 
             if j == @c_user.length and @c_user.more and !nomore then
                cont = moreprompt
                j = 1
              end 
              break if !cont
     
        print "#{i.name.ljust(35)} ... #{i.summary}" if i.name[0].upcase >= startchar}
     print
     print "%Y;  *** End of Directory Listing *** "
  end

  def profilemenu
    theme = get_user_theme(@c_user) 
    GraphFile.new(self, "profilemenu",true).ogfileout(0)
    prompt = theme.profile_prompt
    print "p_total #{p_total}"
    getinp(prompt) {|inp|

      if !inp.integer?
        parameters = Parse.parse(inp)
        inp.gsub!(/[-\d]/,"")
      end
      case inp.upcase

      when "?"; GraphFile.new(self, "profilemenu",true).ogfileout(0)
      when "Y"; if @c_user.profile_added then profileeditmenu else profileadd end
      when "G"; GraphFile.new(self, "profileinfo",true).ogfileout(0)
      when "L"; findprofile
      when "TB"; alpha_list("A")
      when "W"; displaywho
      when "PU"; page    
      when "";	done = true
      when "Q";	done = true
      when "X";	done = true
      end
      done
    }
  end 
  
  

   def showprofile(ppointer)
      GraphFile.new(self, "proentry").profileout(fetch_user(fetch_profile_list[ppointer-1].number))
   end

  def findprofile
     theme = get_user_theme(@c_user) 
     getinp(theme.proflle_lookup) {|inp| 
     
      case inp.upcase
          when "B"; profilebrowse(nil)
	  when "X"; return
       else
	if 
	 index = get_profile_index(inp)
	 if !index.nil? then
	   done=true
	   profilebrowse(index+1)
        end
      end
     end
     done
     }
  end
  
  def profilebrowse(startuser)
    
    total =p_total
    if startuser.nil? then
	startuser = 1
    else
        showprofile(startuser)
    end
    readmenu(
      :initval => startuser,
      :range => 1..(p_total ),
      :loc => PROFILE
    ) {|sel, ppointer, moved|
      if !sel.integer?
        sel.gsub!(/[-\d+]/,"")
      end

      showprofile(ppointer) if moved
      case sel
      when "/"; showprofile(ppointer)
      when "Y"; if @c_user.profile_added then profileeditmenu else profileadd end
      when "G"; GraphFile.new(self, "profileinfo",true).ogfileout(0)
      when "Q"; ppointer = true
      when "W"; displaywho
      when "PU"; page    
      when "G"; leave
      when "?"; GraphFile.new(self, "profilereadmnu",true).ogfileout(0)
      end # of case
      p_return = [ppointer,p_total ]

    }
  end


  


















  

  
  
end #class Session





