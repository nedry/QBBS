class Session
	
def version

 print	
 print "%C;#{VER} (C) Copyright 1985 - 2010 by Fly-By-Night Software"
 print
 print "%G;Programmers:"
 print
 print "     %WC;Mark Firestone%W;   %WG;Martin DeMello%W;    %WR;John Lorance%W;"
 print 			     
 print "%G;Thanks to:"
 print		
 print "           %WB;Wayne Conrad%W;          %WY;Rob Swindell%W;"
 print			
 print "%C;For all their help and encouragement."
 print			
 print "%G;APIs by:"
 print		       
 print "      %M;Datamapper (Database)...........%W;The Datamapper Team"
 print "      %M;Natter (IRC)....................%W;Johnathan Perkins "
 print "      %M;RubyMail (SMTP Email)...........%W;Matt Armstrong      "
 print
end

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
		%M%It's a stiff!  Bereft of life, it rests in peace!  If you
		hadn't pressed 'Q' it'd be pushing up the daisies!
		It's metabolic processes are now 'istory!  It's off the twig!
		It's kicked the bucket, It's shuffled off it's mortal coil, run 
		down the curtain and joined the bleedin' choir invisibile!!\r\n
		%R%THIS IS AN EX-QUESTIONAIRE!!\r\n
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
