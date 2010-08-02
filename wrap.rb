#Subject: [ruby-talk:10587] Re: Word wrap algorithm
#From: Kevin Smith <sent qualitycode.com>
#Date: Fri, 9 Feb 2001 01:35:37 +0900
#Morris, Chris wrote:
#>I'm in need of a word wrap method -- anyone know of an existing one
#>(preferably in Ruby) I could use?

#Here's one I threw together, and it has worked 
#well enough for my simple needs for a couple 
#months. YMMV, but at least it's a starting point. 
#I paid no attention to speed, and wasn't all that 
#familiar with Ruby when I wrote it.

#Feel free to use it however you wish.

#Kevin

class WordWrapper
	def WordWrapper.wrap(text, margin)
		wrapper = WordWrapper.new
		return wrapper.doWrap(text, margin)
	end

	def doWrap(text, margin)
		output = ''
		text.each_line do #1.9 fix
			| paragraph |
			if (paragraph !~ /^>/)
				paragraph = wrapParagraph(paragraph, margin-1)
			end
			output += paragraph
		end
		return output
	end

private
	def wrapParagraph(paragraph, width)
		lineStart = 0
		lineEnd = lineStart + width
		while lineEnd < paragraph.length
			newLine = paragraph.index("\n", lineStart)
			if newLine && newLine < lineEnd
				lineStart = newLine+1
				lineEnd = lineStart + width
				next
			end
			tryAt = lastSpaceOnLine(paragraph, lineStart, lineEnd)
			paragraph[tryAt] = paragraph[tryAt].chr + "\r\n"
			tryAt += 2
			lineStart = findFirstNonSpace(paragraph, tryAt)
			paragraph[tryAt...lineStart] = ''
			lineStart = tryAt
			lineEnd = lineStart+width
		end
		return paragraph
	end

	def findFirstNonSpace(text, startAt)
		startAt.upto(text.length) do
			| at |
			if text[at] != 32
				return at
			end
		end
		return text.length
	end

	def lastSpaceOnLine(text, lineStart, lineEnd)
		lineEnd.downto(lineStart) do
			| tryAt |
			case text[tryAt].chr
				when ' ', '-'
					return tryAt
			end
		end
		return lineEnd
	end
		
end

