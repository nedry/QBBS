def readmenu(args)
	dir = +1
	sdir = '+'
	ptr = args[:initval] || 1
  
	range = args[:range]
	out = nil
        out = args[:out]
	done = false
	o_prompt = args[:prompt]
	high = args[:range].last
	while true

	prmpt = o_prompt.gsub("%p","#{ptr}")
	inp = getinp(eval(prmpt),false)
		oldptr = ptr
		sel = inp.upcase
 
 # Martin, can you do this better?
	        high = 0 if high.nil?
		low = args[:range].first
	        low = 0 if low.nil?
		ptr = 0 if ptr.nil?
		
		
		case sel
		when ""; ptr = (dir == 1) ? up(ptr, high,out) : down(ptr, low)
		when "-"; dir = -1; ptr = down(ptr, low)
		when "+"; dir = +1; ptr = up(ptr, high,out)
		when /\d+/
		 ptr = jumpto(ptr, sel.to_i, low,high) if sel.to_i != 0
		#when /[0..9]/; ptr = jumpto(ptr, sel.to_i, low,high)
		end 
		moved = (ptr != oldptr)
		ptr,high = yield(sel, ptr, moved)
#print ptr == true
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
		print("%RCan't go higher")
	 end
	end
	ptr
	#return [ptr,out]
end

def down(ptr, low)
	if ptr > low then
		ptr = ptr - 1
	else
		print("%GCan't go lower")
	end
	ptr
end

def jumpto(ptr, newptr, low, high)
	if (newptr >= low) and (newptr <= high) then 
		ptr = newptr
	else
         print "Im here"
		print "Out of Range."
		ptr
	end
end

