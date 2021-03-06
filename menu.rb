def readmenu(args)
  dir = +1
  sdir = '+'
  ptr = args[:initval] || 1

  range = args[:range]
  zip = args[:zip]
  done = false
  # o_prompt = args[:prompt]
  theme = args[:theme]
  l_read = args[:l_read]
  aname = args[:aname],
  high = args[:range].last
  loc = args[:loc]

  while !done
    area = fetch_area(@c_area)
    o_prompt = "Not Found: "
    case loc
    when READ
      o_prompt = message_prompt(theme.read_prompt,SYSTEMNAME,@c_area,0,l_read,h_msg,area.name,sdir).gsub("%p","#{ptr}")
      o_prompt = "%G;ZIP: " + o_prompt if zip
    when BULLETIN
      o_prompt = eval('"%W;#{sdir}Bulletin [%p] (1-#{b_total}): "').gsub("%p","#{ptr}")
    when USER
      o_prompt = eval('"%W;#{sdir}User [%p] (1-#{u_total}): "').gsub("%p","#{ptr}")
    when BBS
      o_prompt = eval('"%W;#{sdir} BBS System [%p] (1-#{bbs_total}): "').gsub("%p","#{ptr}")
    when THEME
      o_prompt = eval('"%W;#{sdir}Theme [%p] (1-#{t_total}): "').gsub("%p","#{ptr}")
    when AREA
      o_prompt = eval('"%W;#{sdir} Area [%p] (0-#{a_total - 1}): "').gsub("%p","#{ptr}")
    when OTHER
      o_prompt = eval('"%W;#{sdir} BBS System [%p] (1-#{o_total}): "').gsub("%p","#{ptr}")
    when DOOR
      o_prompt = eval('"%G;#{sdir}Door [%p] (1-#{d_total}): %W;"').gsub("%p","#{ptr}")
    when SCREEN
      o_prompt = eval('"%G;#{sdir}Screen [%p] (1-#{s_total}): %W;"').gsub("%p","#{ptr}")
    when GROUP
      o_prompt = eval('"%G;#{sdir}Group [%p] (0-#{g_total-1}): %W;"').gsub("%p","#{ptr}")
    when PROFILE
      o_prompt = eval('"%G;#{sdir}Profile [%p] (1-#{p_total}): %W;"').gsub("%p","#{ptr}")
    end

    inp  = getinp (o_prompt)
    oldptr = ptr
    sel = inp.upcase

    high ||= 0
    low = args[:range].first || 0
    ptr ||= 0 if ptr.nil?

    case sel
    when ""; ptr,done = (dir == 1) ? up(ptr, high, zip) : down(ptr, low)
    when "-"; dir = -1; ptr = down(ptr, low)
    when "+"; dir = +1; ptr,done = up(ptr, high, zip)
    when /\d+/
      ptr = jumpto(ptr, sel.to_i, low, high) if sel.to_i != 0
    end
    moved = (ptr != oldptr)
    ptr, high = yield(sel, ptr, moved)
    break if ptr == true # exit if a -1 is returned
    sdir = (dir > 0) ? '+' : '-'
  end
end

def up(ptr, high, zip)
  #print "ptr: #{ptr} high: #{high}"
  if ptr < high
    ptr = ptr + 1
  else
    if zip then
      stop = zipscan(@c_area)
      if stop.nil? then

        return [ptr,true]

      else ptr = stop
      end
    else
      print("%WR; Can't go higher %W;")
    end
  end
  return [ptr,false]
end

def down(ptr, low)
  if ptr > low then
    ptr = ptr - 1
  else
    print("%WG; Can't go lower %W;")
  end
  ptr
end

def jumpto(ptr, newptr, low, high)
  if (newptr >= low) and (newptr <= high) then
    newptr
  else
    print "%WR; Out of Range. %W;"
    ptr
  end
end
