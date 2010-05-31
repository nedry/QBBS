class Session
	def pick_one(sequence) 
		sequence[rand(sequence.length)] 
	end 

	def timeofday
		hour = Time.now.hour
		timeofday = (
			case hour
			when 0..11; "Morning"
			when 12..17; "Afternoon"
			when 17..24; "Evening"
			end 
		)
	end
end
