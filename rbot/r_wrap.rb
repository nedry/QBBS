 
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
		