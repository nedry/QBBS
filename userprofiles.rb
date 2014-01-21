class Session
  include Comparable

  # TODO: instead of a block. take in a key
  # Then use @c_user.update(key => temp)
  # You can do this in several other places too when setting a bunch of object
  # properties using the same pattern (see datamapper docs)
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
    done = false
    GraphFile.new(self, "proedit").profileout(@c_user)
    prompt = theme.profileedit_prompt
    getinp(prompt) {|inp|


      parameters = Parse.parse(inp)

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

      when @cmd_hash["upmenu"] ; run_if_ulevel("upmenu") { GraphFile.new(self, "proedit",true).ogfileout(0)}
      when @cmd_hash["who"] ; run_if_ulevel("who") {displaywho}
      when @cmd_hash["upexit"] ; run_if_ulevel("upexit") {done = true}
      end
      GraphFile.new(self, "proedit").profileout(@c_user) if !done
      done
    }
  end

  def alpha_list
    j = 1
    cont = true
    nomore = false
    nonstop = false
    startchar = ""
    theme = get_user_theme(@c_user)
    getinp (theme.profile_full_prompt) {|inp|
      if inp.upcase =~ (/^[A-Z]$/)  then
        startchar = inp.upcase
        break
      end
    }
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
    done = false

    GraphFile.new(self, "profilemenu",true).ogfileout(0)
    prompt = theme.profile_prompt

    getinp(prompt) {|inp|


      parameters = Parse.parse(inp)

      case inp.upcase
      when @cmd_hash["upmenu"] ; run_if_ulevel("upmenu") { GraphFile.new(self, "profilemenu",true).ogfileout(0)}
      when @cmd_hash["upadd"] ; run_if_ulevel("upadd") {if @c_user.profile_added then profileeditmenu else profileadd end}
      when @cmd_hash["upinfo"] ; run_if_ulevel("upinfo") { GraphFile.new(self, "profileinfo",true).ogfileout(0)}
      when @cmd_hash["upfind"] ; run_if_ulevel("upfind") {findprofile}
      when @cmd_hash["who"] ; run_if_ulevel("who") {displaywho}
      when @cmd_hash["palpha"] ; run_if_ulevel("palpha") {alpha_list}
      when @cmd_hash["page"] ; run_if_ulevel("page") {page}
      when @cmd_hash["upexit"] ; run_if_ulevel("upexit") { done = true}
      end
      done
    }

  end



  def showprofile(ppointer)
    GraphFile.new(self, "proentry").profileout(fetch_user(fetch_profile_list[ppointer-1].number),ppointer)  if p_total > 0
  end

  def findprofile
    theme = get_user_theme(@c_user)
    getinp(theme.proflle_lookup) {|inp|

      case inp.upcase
      when @cmd_hash["who"] ; run_if_ulevel("who") {displaywho}
      when @cmd_hash["page"] ; run_if_ulevel("page") {page}
      when @cmd_hash["upbrowse"] ; run_if_ulevel("upbrowse") {profilebrowse(nil) if !theme.profile_flat_menu}
      when @cmd_hash["upexit"] ; run_if_ulevel("upexit") {return}
      else
        if
          index = get_profile_index(inp)
          if !index.nil? then
            done=true
            if !theme.profile_flat_menu then
              profilebrowse(index+1)
            else
              return index+1
            end
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
      GraphFile.new(self, "profilereadmnu",true).ogfileout(0)
    else
      showprofile(startuser)
    end
    readmenu(
    :initval => startuser,
    :range => 1..(p_total ),
    :loc => PROFILE
    ) {|sel, ppointer, moved|

      showprofile(ppointer) if moved
      case sel
      when "/"; showprofile(ppointer)
      when @cmd_hash["upadd"] ; run_if_ulevel("upadd") {if @c_user.profile_added then profileeditmenu else profileadd end}
      when @cmd_hash["upinfo"] ; run_if_ulevel("upinfo") { GraphFile.new(self, "profileinfo",true).ogfileout(0)}
      when @cmd_hash["upexit"] ; run_if_ulevel("upexit") { ppointer = true}
      when @cmd_hash["upfind"] ; run_if_ulevel("upfind") {ppointer = findprofile; showprofile(ppointer)}
      when @cmd_hash["who"] ; run_if_ulevel("who") {displaywho}
      when @cmd_hash["palpha"] ; run_if_ulevel("palpha") {alpha_list}
      when @cmd_hash["page"] ; run_if_ulevel("page") {page}
      when @cmd_hash["upmenu"] ; run_if_ulevel("upmenu") { GraphFile.new(self, "profilereadmnu",true).ogfileout(0)}
      end # of case
      p_return = [ppointer,p_total ]

    }
  end

























end #class Session





