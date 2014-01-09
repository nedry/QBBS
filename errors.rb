class Session
	


def crerror
	print <<-EOP
		\r\n%G;When the software asks you to enter <%Y;CR%G;> it means
		press carriage return, not type a %Y;C %G;and a %Y;R%G;.
		Thoughtful users will realize that this also means
		press the <%Y;ENTER%G;> key.  Have a nice day.\r\n
	EOP
	false
end

def questionaire
	print <<-EOP
		%G;\r\nThis Questionaire has ceased to be!  It's expired and
		gone to meet it's maker!\r\n
		%M;It's a stiff!  Bereft of life, it rests in peace!  If you
		hadn't pressed 'Q' it'd be pushing up the daisies!
		It's metabolic processes are now 'istory!  It's off the twig!
		It's kicked the bucket, It's shuffled off it's mortal coil, run 
		down the curtain and joined the bleedin' choir invisibile!!\r\n
		%R;THIS IS AN EX-QUESTIONAIRE!!\r\n
	EOP
end

def spam
	write('Spam, Spam, Bacon, Spam...');
	sleep (0.5)
	27.times {write(BS.chr); sleep(0.02)}
	27.times {write(SPACE)}
	27.times { write(BS.chr)}
end

end #class Session
