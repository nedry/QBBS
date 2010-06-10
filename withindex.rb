module Enumerable
	def method_missing(meth, *args, &block)
		if meth.to_s =~ /_with_index/
			m = meth.to_s.gsub!('_with_index','')
			i = -1
			self.send(m,*args) {|n|
				i = i+1
				block.call(n,i)
			}
		end
	end
end

