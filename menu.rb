def readmenu(args)
  dir = +1
  sdir = '+'
  ptr = args[:initval] || 1

  range = args[:range]
  out = args[:out]
  done = false
  o_prompt = args[:prompt]
  high = args[:range].last

  while true
    prmpt = o_prompt.gsub("%p","#{ptr}")
    inp = getinp(eval(prmpt))
    oldptr = ptr
    sel = inp.upcase

    high ||= 0
    low = args[:range].first || 0
    ptr ||= 0 if ptr.nil?

    case sel
    when ""; ptr = (dir == 1) ? up(ptr, high, out) : down(ptr, low)
    when "-"; dir = -1; ptr = down(ptr, low)
    when "+"; dir = +1; ptr = up(ptr, high, out)
    when /\d+/
      ptr = jumpto(ptr, sel.to_i, low, high) if sel.to_i != 0
    end 
    moved = (ptr != oldptr)
    ptr, high = yield(sel, ptr, moved)
    break if ptr == true # exit if a -1 is returned
    sdir = (dir > 0) ? '+' : '-'
  end
end

def up(ptr, high, out)
  if ptr < high
    ptr = ptr + 1
  else
    if out == "ZIPread" then
      stop = zipscan(@c_area)
      if stop.nil? then return else ptr = stop end
    else
      print("%WR%Can't go higher%W%")
    end
  end
  ptr
end

def down(ptr, low)
  if ptr > low then
    ptr = ptr - 1
  else
    print("%WG%Can't go lower%W%")
  end
  ptr
end

def jumpto(ptr, newptr, low, high)
  if (newptr >= low) and (newptr <= high) then 
    newptr
  else
    print "%WR%Out of Range.%W%"
    ptr
  end
end
