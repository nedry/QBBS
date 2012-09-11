 
 #fortune file reader based on PHP code by:   
 #Henrik Aasted Sorensen, henrik@aasted.org
 #Read more at http://www.aasted.org/quote
require "date"

def readLong(file) 
	data = file.read(4)
	result = data[3].ord
	result += data[2].ord << 8
	result += data[1].ord << 16
	result += data[0].ord << 24
	return result
end
	
def getNumberOfQuotes(file)

	if File.exists?(file) then
	  file_handle = File.open(file, "rb")
	  junk = readLong(file_handle)  #Just move over the first long. 
	  result =  readLong(file_handle)
	  file_handle.close
	end
	  return result
	end
	
def getQuote(file_handle,index) 
	 file_handle.seek(index)
	 line=""; result = ""

	 while ( line.strip != "%") && (!file_handle.eof) 
		result = result + line		
	 	line = file_handle.gets(1024) 
	 end

	 return result
end


def getExactQuote(file,index) 
	
	if File.exists?(file) then
		file_handle = File.open(file, "rb")
		file_handle.seek(24 + 4 * index)
    phys_index = readLong(file_handle)
	  file_handle.close
	else
    puts "-QOTD: Can't read index"
		return
	end
	
	qfilename = file.chop.chop.chop.chop
	
	if File.exists?(qfilename) then	
    quotefile = File.open(qfilename, "rb")
		quote = getQuote(quotefile,phys_index)
		quotefile.close
	else
		puts "-QOTD: Can't read quote datafile"
	end
	 return quote	
end

def getRandomQuote(file)
	  number = getNumberOfQuotes(file);
		if !number.nil? then
      index = rand(number-1);
		  return getExactQuote(file,index);
    else
	    return "QOTD File Missing, please tell sysop..."
		end
end



def quoteFromDir(dir) 
	amount = 0
	index = 0
	files = []
	quotes = []
	if File.exists?(dir) && File.directory?(dir)
	  Dir.entries(dir).each {|entry|	
		  if entry.index(".dat",-4) then
			  number = getNumberOfQuotes("#{dir}/#{entry}")
			  amount += number
			  quotes << amount
			  files << entry
		  end
		  }
	  index = rand(amount)
    i = 0
	  while (quotes[i] < index)  
	  	i += 1
	  end				
    return getRandomQuote("#{dir}/#{files[i]}")
	else
		return "Quote of the day directory missing, please tell sysop..."
	end
end

def get_history(datafile)
 #/home/mark/QBBS/tih.dat
 #/usr/share/games/fortunes/quotes.dat
day_to_display = Time.now.strftime("%j").to_i - 1

#correct for leap year, or rather, not having one.

day_to_dispay = day_to_display - 1 if Date.leap?(Time.now.year) and day_to_display > 59 

numofquotes = getNumberOfQuotes(datafile)
puts "number of TIH: #{numofquotes}"

return getExactQuote(datafile,day_to_display)

end

