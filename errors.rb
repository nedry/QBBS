class Session
	
def version

 print	
 print "%C#{VER} (C) Copyright 1985 - 2010 by Fly-By-Night Software"
 print
 print "%GProgrammers:"
 print
 print "     %CMark Firestone   %GMartin DeMello    %RJohn Lorance"
 print 			     
 print "%GThanks to:"
 print		
 print "           %MWayne Conrad          %RRob Swindell"
 print			
 print "%CFor all their help and encouragement."
 print			
 print "%GAPIs by:"
 print		       
 print "      %MDatamapper (Database)...........%WThe Datamapper Team"
 print "      %MNatter (IRC)....................%WJohnathan Perkins "
 print "      %MRubyMail (SMTP Email)...........%WMatt Armstrong      "
 print
end

def crerror
	print <<-EOP
		\r\n%GWhen the software asks you to enter <%YCR%G> it means
		press carriage return, not type a %YC %Gand a %YR%G.
		Thoughtful users will realize that this also means
		press the <%YENTER%G> key.  Have a nice day.\r\n
	EOP
	false
end

def questionaire
	print <<-EOP
		%G\r\nThis Questionaire has ceased to be!  It's expired and
		gone to meet it's maker!\r\n
		%MIt's a stiff!  Bereft of life, it rests in peace!  If you
		hadn't pressed 'Q' it'd be pushing up the daisies!
		It's metabolic processes are now 'istory!  It's off the twig!
		It's kicked the bucket, It's shuffled off it's mortal coil, run 
		down the curtain and joined the bleedin' choir invisibile!!\r\n
		%RTHIS IS AN EX-QUESTIONAIRE!!\r\n
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
