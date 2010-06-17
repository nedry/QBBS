# encoding:  ISO-8859-1

BBS_COLORTABLE = {
	'%R' => "<span style='color: #fc5454'>", 
	'%G' => "<span style='color: #54fc54'>",
	'%Y' => "<span style='color: #fcfc54'>",
	'%B' => "<span style='color: #5454fc'>",
	'%M' => "<span style='color: #fc54fc'>",
	'%C' => "<span style='color: #54fcfc'>",
	'%W' =>"<span style='color: white'>",
	'%r' => "<span style='color: #a80000'>",
	'%g' => "<span style='color: #00a800'>",
	'%y' => "<span style='color: #a85400'>",
	'%b' => "<span style='color: #0000a8'>", 
	'%m' => "<span style='color: #a800a8'>",
	'%c' => "<span style='color: #00a8a8'>", 
	'%w' => "<span style='color: #a8a8a8'>"}

 BOLD_ANSI_FG_TABLE = {"0" => "color: #545454;",  # grey
					"1" => "color: #fc5454;",  # bright red
					"2" => "color: #54fc54;",  # bright green
					"3" => "color: #fcfc54;",  # bright yellow
					"4" => "color: #5454fc;",  # bright blue
					"5" => "color: #fc54fc;",  # bright magenta
					"6" => "color: #54fcfc;",  # bright cyan
					"7" => "color: white;"}    # bright white
					
 ANSI_FG_TABLE = {"0" => "color: black;",
			      "1" => "color: #a80000;",  # red
			      "2" => "color: #00a800;",  # green
			      "3" => "color: #a85400;",  # yellow
			      "4" => "color: #0000a8;",  # blue
			      "5" => "color: #a800a8;",  # magenta
			      "6" => "color: #00a8a8;",  # cyan
			      "7" => "color: #a8a8a8;"} # white
			      
ANSI_BG_TABLE = {"0" => "background-color: black;",
			      "1" => "background-color: #a80000;", # red
			      "2"=> "background-color: #00a800;",  # green
			      "3"=> "background-color: #a85400;",  # dark yellow (brown)
			      "4"=> "background-color: #0000a8;",  # blue
			      "5" => "background-color: #a800a8;",  # magenta
			      "6" => "background-color: #00a8a8;",  # cyan
			      "7" => "background-color: #a8a8a8;"  # white
			      }

					

EXTENDED_ANSI_TABLE = {
         0.chr => "nbsp",  	# NULL non-breaking space 
	 1.chr => "&#9786",	# white smiling face */
	 2.chr => "&#9787", # black smiling face
	 3.chr => "&hearts",# black heart suit 
	 4.chr => "&diams", # black diamond suit 
	 5.chr =>	"&clubs",  # black club suit */
	 6.chr => "&spades", # black spade suit 
	 7.chr => "&bull",  # bullet 
	 8.chr => "&#9688", # inverse bullet 
	 9.chr => "&#9702", # white bullet 
#	 10.chr => "&#9689", # inverse white circle 
	 11.chr => "&#9794", # male sign 
	 12.chr => "&#9792", # female sign 
#	 13.chr => "&#9834", # eighth note 
	 14.chr => "&#9835", # beamed eighth notes 
	 15.chr => "&#9788", # white sun with rays 
	 16.chr => "&#9654",  # black right-pointing triangle 
	 17.chr => "&#9664", # black left-pointing triangle 
	 18.chr => "&#8597", # up down arrow 
	 19.chr => "&#8252", # double exclamation mark 
	 20.chr => "&para",  # pilcrow sign 
	 21.chr =>  "&sect", # section sign 
	 22.chr => "&#9644", # black rectangle 
	 23.chr => "&#8616",  # up down arrow with base 
	 24.chr => "&uarr",  # upwards arrow 
	 25.chr => "&darr",  # downwards arrow 
	 26.chr => "&rarr", # rightwards arrow 
	# 27.chr => "&larr",  # leftwards arrow 
	 28.chr =>  "&#8985", # turned not sign 
	 29.chr => "&harr", # left right arrow 
	 30.chr => "&#9650", # black up-pointing triangle 
	 31.chr => "&#9660",  #] black down-pointing triangle 
        227.chr => "<br>",
	32.chr => "&nbsp;",
	128.chr => "&Ccedil;",	#128 C, cedilla (199)
	129.chr => "&uuml;",	#129 u, umlaut (252)
	130.chr => "&eacute;",	#130 e, acute accent (233)
	131.chr => "&acirc;", 	#131 a, circumflex accent (226)
	132.chr => "&auml;",	#132 a, umlaut  (228)
	133.chr => "&agrave;",	#133 a, grave accent (224) 
	134.chr => "&aring;",	#134 a, ring (229)
	135.chr => "&ccedil;",	#135 c, cedilla (231)
	136.chr => "&ecirc;",	#136 e, circumflex accent (234)
	137.chr => "&euml;",	#137 e, umlaut (235)
	138.chr => "&egrave;",	#138 e, grave accent (232)
	139.chr => "&iuml;",	#139 i, umlaut (239)
	140.chr => "&icirc;",	#140 i, circumflex accent (238)
	141.chr => "&igrave;",	#141 i, grave accent (236)
	142.chr => "&Auml;",	#142 A, umlaut (196)
	143.chr => "&Aring;",	#143 A, ring (197)
	144.chr => "&Eacute;",	#144 E, acute accent (201)
	145.chr => "&aelig;",	#145 ae ligature (230)
	146.chr => "&AElig;",	#146 AE ligature (198)
	147.chr => "&ocirc;",	#147 o, circumflex accent (244)
	148.chr => "&ouml;",	#148 o, umlaut (246)
	149.chr => "&ograve;",	#149 o, grave accent (242)
	150.chr => "&ucirc;",	#150 u, circumflex accent (251)
	151.chr => "&ugrave;",	#151 u, grave accent (249)
	152.chr => "&yuml;",	#152 y, umlaut (255)
	153.chr => "&Ouml;",	#153 O, umlaut (214)
	154.chr => "&Uuml;",	#154 U, umlaut (220)
	155.chr => "&cent;",	#155 Cent sign (162)
	156.chr => "&pound;",	#156 Pound sign (163)
	157.chr => "&yen;",	#157 Yen sign (165)
	158.chr => "&#8359",	#158 Pt (unicode)
	159.chr => "&#402",	#402 Florin (non-standard alsi 159?)
	160.chr => "&aacute;",	#160 a, acute accent (255)
	161.chr => "&iacute;",	#161 i, acute accent (237)
	162.chr => "&oacute;",	#162 o, acute accent (243)
	163.chr => "&uacute;",	#163 u, acute accent (250)
	164.chr => "&ntilde;",	#164 n, tilde (241)	
	165.chr => "&Ntilde;",	#165 N, tilde (209)
	166.chr => "&ordf;" ,	#166 Feminine ordinal (170)
	167.chr => "&ordm;",	#167 Masculine ordinal (186)	
	168.chr => "&iquest;",	#168 Inverted question mark (191)
	169.chr => "&#8976",	#169 Inverse "Not sign" (unicode)
	170.chr => "&not;",	#170 Not sign (172)
	171.chr => "&frac12;",	#171 Fraction one-half (189)
	172.chr => "&frac14;",	#172 Fraction one-fourth (188)
	173.chr => "&iexcl;",	#173 Inverted exclamation point (161)
	174.chr => "&laquo;",	#174 Left angle quote (171)
	175.chr => "&raquo;",	#175 Right angle quote (187)
	176.chr => "&#9617",	#176 drawing symbol (unicode) 
	177.chr => "&#9618",	#177 drawing symbol (unicode) 
	178.chr => "&#9619",	#178 drawing symbol (unicode) 
	179.chr => "&#9474",	#179 drawing symbol (unicode) 
	180.chr => "&#9508",	#180 drawing symbol (unicode) 
	181.chr => "&#9569",	#181 drawing symbol (unicode)
	182.chr => "&#9570",	#182 drawing symbol (unicode)
	183.chr => "&#9558",	#183 drawing symbol (unicode) 
	184.chr => "&#9557",	#184 drawing symbol (unicode)
	185.chr => "&#9571",	#185 drawing symbol (unicode)
	186.chr => "&#9553",	#186 drawing symbol (unicode)
	187.chr => "&#9559",	#187 drawing symbol (unicode)
	188.chr => "&#9565",	#188 drawing symbol (unicode)
	189.chr => "&#9564",	#189 drawing symbol (unicode)
	190.chr => "&#9563",	#190 drawing symbol (unicode)
	191.chr => "&#9488",	#191 drawing symbol (unicode)
	192.chr => "&#9492",	#192 drawing symbol (unicode)
	193.chr => "&#9524",	#193 drawing symbol (unicode)
	194.chr => "&#9516",	#194 drawing symbol (unicode)
	195.chr => "&#9500",	#195 drawing symbol (unicode)
	196.chr => "&#9472",	#196 drawing symbol (unicode)
	197.chr => "&#9532",	#197 drawing symbol (unicode)
	198.chr => "&#9566",	#198 drawing symbol (unicode)
	199.chr => "&#9567",	#199 drawing symbol (unicode)
	200.chr => "&#9562",	#200 drawing symbol (unicode)
	201.chr => "&#9556",	#201 drawing symbol (unicode) 
	202.chr => "&#9577",	#202 drawing symbol (unicode)
	203.chr => "&#9574",	#203 drawing symbol (unicode)
	204.chr => "&#9568",	#204 drawing symbol (unicode)
	205.chr => "&#9552",	#205 drawing symbol (unicode)
	206.chr => "&#9580",	#206 drawing symbol (unicode)
	207.chr => "&#9575",	#207 drawing symbol (unicode)
	208.chr => "&#9576",	#208 drawing symbol (unicode)
	209.chr => "&#9572",	#209 drawing symbol (unicode)
	210.chr => "&#9573",	#210 drawing symbol (unicode)
	211.chr => "&#9561",	#211 drawing symbol (unicode)
	212.chr => "&#9560",	#212 drawing symbol (unicode)
	213.chr => "&#9554",	#213 drawing symbol (unicode)
	214.chr => "&#9555",	#214 drawing symbol (unicode)
	215.chr => "&#9579",	#215 drawing symbol (unicode)
	216.chr => "&#9578",	#216 drawing symbol (unicode)
	217.chr => "&#9496",	#217 drawing symbol (unicode)
	218.chr => "&#9484",	#218 drawing symbol (unicode)
	219.chr => "&#9608",	#219 drawing symbol (unicode)
	220.chr => "&#9604",	#220 drawing symbol (unicode)
	221.chr => "&#9612",	#221 drawing symbol (unicode)
	222.chr => "&#9616",	#222 drawing symbol (unicode)
	223.chr => "&#9600",	#223 drawing symbol (unicode)
	224.chr => "&#945",	#224 alpha symbol 
	225.chr => "&szlig;",	#225 sz ligature (beta symbol) (223)
	226.chr => "&#915",	#226 omega symbol 
#	227.chr => "&#960",	#227 pi symbol
	228.chr => "&#931",	#228 epsilon symbol
	229.chr => "&#963",	#229 o with stick
	230.chr => "&micro;",	#230 Micro sign (Greek mu) (181)
	231.chr => "&#964",	#231 greek char?
	232.chr => "&#934",	#232 greek char?
	233.chr => "&#920",	#233 greek char?
	234.chr => "&#937",	#234 greek char?
	235.chr => "&#948",	#235 greek char?
	236.chr => "&#8734",	#236 infinity symbol (unicode)
	237.chr => "&oslash;",	#237 Greek Phi (966) 
	238.chr => "&#949",	#238 rounded E
	239.chr => "&#8745",	#239 upside down U (unicode)
	240.chr => "&#8801",	#240 drawing symbol (unicode) 
	241.chr => "&plusmn;",	#241 Plus or minus (177)
	242.chr => "&#8805",	#242 drawing symbol (unicode)
	243.chr => "&#8804",	#243 drawing symbol (unicode)
	244.chr => "&#8992",	#244 drawing symbol (unicode)
	245.chr => "&#8993",	#245 drawing symbol (unicode)
	246.chr => "&divide;",	#246 Division Sign (247)
	247.chr => "&#8776",	#247 two squiggles (unicode)
	248.chr => "&deg;",	#248 Degree Sign (176)
	249.chr => "&#8729",	#249 drawing symbol (unicode)
	250.chr => "&middot;",	#250 Middle dot
	251.chr => "&#8730",	#251 check mark (unicode)
	252.chr => "&#8319",	#252 superscript n (unicode)
	253.chr => "&sup2;",	#253 superscript 2 (178)
	254.chr => "&#9632",	#254 drawing symbol (unicode)
	255.chr => "&nbsp;",	#255 non-blanking space

}

	def parse_ansi_ext(str)

			EXTENDED_ANSI_TABLE.each_pair {|color, result|
				str = str.gsub(color,result)
			}
		return str
	end
	
	def parse_bbs_color(str)

			BBS_COLORTABLE.each_pair {|color, result|
			       # s_color = color
				str = str.gsub(color,result)
			}
		return str
	end

	def parse_fgcolor(dude)
	  result=ANSI_FG_TABLE.fetch(dude.to_s)
	  return result
	end
	
	def parse_fg_bold_color(dude)
          result= BOLD_ANSI_FG_TABLE.fetch(dude.to_s)
	  return result
	end

	def parse_bg_color(dude)
	  result= ANSI_BG_TABLE.fetch(dude.to_s)
	  return result
	end


def parse_ansi(str)
	
	outstr = ""
	l_fg = 7
	l_bg = 0
	bold = false
	underline = false
	result = ""
	output = ""

	str.gsub!(/\e\[(\d+)(?:;(\d+)(?:;(\d+))?)?(\D)/){|code| 
										
									      
									      command = ""
									      result = ""
									      value = ""
									
									      array = [$1,$2 ,$3].compact
									      case $4
										      when "C"
											if !array[0].nil? then
											  array[0].to_i.times {result << "&nbsp;"}
											  doit = false
										  end
										   #  when "A" #cursor up
										  #   doit= false
										      when "m"
										        
											array.each {|color| c = color.to_i
										                          #    puts "l_fg:#{l_fg}"
													 #     puts "l_bg:#{l_bg}"
											                          fg = l_fg
														  bg = l_bg
														  doit = true
														  replace = ""
											                     case c
														when 0  #reset
														#bold = false
														 bold = true
														 blink = false
														 fg = 7
														 bg  = 0
														when  1 #bold
														  bold = true
														  doit= false
														 when 2 #not-bold
														  bold = false
														  doit=true
														 when 5 #blink
														  blink = true
														  doit=true
														 when 6 #fast blink 
														  blink = true
														  doit=false
														 when 7 #inverse
														   fg =l_bg
														   bg = l_fg
														else
														 fg = c - 30  if c > 29 and c < 38
														 bg = c - 40 if c > 39 and c <  48
													      end		
													#	puts "fg:#{fg}"
													#	puts "bg:#{bg}"
														if doit then
														  result = "</span><span style='"
                                                                                                                  if fg != l_fg and fg != -1 then
														     l_fg = fg
													           end
													          if bg != l_bg and bg !=-1 then
														    l_bg = bg
													           end 
													          result << parse_bg_color(bg)
												                   if bold
														    result <<  parse_fg_bold_color(fg) 
													          else 
														   result << parse_fgcolor(fg)
													          end
													        if blink then 
														  result << "text-decoration:blink;"
														end
													         result << "'>"
												              end
												  
													} 
											end		  
					result		 	}
									
 return str
 end
 
 def parse_webcolor(instr)
  #puts  instr.encode("US-ASCII")
  out = parse_ansi( parse_ansi_ext(instr))
  out = parse_bbs_color(out)
  return out
end
