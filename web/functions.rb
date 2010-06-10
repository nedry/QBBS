

DB_UID="mark"
DB_PASSWD="yakxmas1"
TITLE = "QBBS Web Interface V.50"
TEXT_ROOT = "/home/mark/qbbs2/text/"
WEB_IDLE_MAX = 1

require "date"
require "time"

#require "/home/mark/qbbs2/tools.rb"

def who_list_add (uid)
  if !who_exists(uid) then
     add_who(uid,Time.now,"Logging in...")
  else 
     update_who(uid,Time.now,"Logging in again...")
 end
end

def who_list_delete (uid)
 if who_exists(uid) then
  delete_who(uid)
 end
 end

 
 def who_list_update(uid,loc)

   update_who(uid,Time.now,loc)
    who_list_check
    if !who_exists(uid) then
      add_who(uid,Time.now,loc)
    end
 end
 

	             
def w_open_database
 
 begin
  @db = PGconn.connect(DATAIP,5432,"","",DATABASE,DB_UID,DB_PASSWD)
 rescue
  print "Fatal Error: Database Connection Failed.  Halted."
 end
end

def close_database
  @db.close
end

WEBCOLORTABLE = {
        "\e[0m" => "</span>",
      #  "\e[1m" => "<span style='font-weight:bold'>",
 "\e[1m" => "",
	"\e[1m\e[31m" => "<span style='color:red'>",
        "\e[1m\e[32m" => "<span style='color:green'>",
	"\e[1m\e[33m" => "<span style='color:yellow'>",
        "\e[1m\e[30m" => "<span style='color:black'>",
        "\e[1m\e[34m" => "<span style='color:blue'>",
	"\e[1m\e[35m" => "<span style='color:'magenta'>",
        "\e[1m\e[36m" => "<span style='color:cyan'>",
	"\e[1m\e[37m" => "<span style='color:white'>",
        "\e[31m" => "<span style='color:darkred'>",
	"\e[32m" => "<span style='color:darkgreen'>",
        "\e[33m" => "<span style='color:darkyellow'>",
	"\e[34m" => "<span style='color:darkblue'>" ,
        "\e[35m" => "<span style='color:'darkmagenta'>",
	"\e[36m" => "<span style='color:darkcyan'>",
        "\e[37m" => "<span style='color:gainsboro'>",
        "\e[40m" => "<span style='background-color:white'>", #don't want black.
        "\e[41m" => "<span style='background-color:red'>",
        "\e[42m" => "<span style='background-color:green'>",
        "\e[43m" => "<span style='background-color:yellow'>",
        "\e[44m" => "<span style='background-color:blue'>",
        "\e[45m" => "<span style='background-color:magenta'>",
        "\e[46m" => "<span style='background-color:cyan'>",
        "\e[47m" => "<span style='background-color:white'>",
        "\e[49m" => "<span style='background-color:white'>",
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
	227.chr => "&#960",	#227 pi symbol
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



	def parse_webcolor(str)
		#str = str.to_s.gsub("\t",'')
			WEBCOLORTABLE.each_pair {|color, result|
				str = str.gsub(color,result)
			}
		return str
	end
  
def print_header
"<!DOCTYPE HTML PUBLIC '-//W3C//DTD HTML 4.01//EN' 'http://www.w3.org/TR/html4/strict.dtd'>"
 "<HEAD><TITLE> "+ TITLE + "</TITLE>"
 "<link rel='stylesheet' type='text/css' href='../qbbs.css'>"
  "<body>"
  "<DIV class='header'>"
 "<h3>QBBS V2.0 retroCOMPUTING BBS &nbsp;&nbsp;Job 1 &nbsp;&nbsp;KB0&nbsp;&nbsp; #{Time.now} </h3>"
 "</div>"
 "<DIV class='main_frame'>"
end

def print_footer
 print '<div style="clear:both">'
 print '<div class="footer">'
 print '<br><br>'
 print '<font color="#000" size="2">&copy; 2010 <a href="about.rbx">Fly-By-Night Software</a><br>'
 print '</font>'
 print '</div></div>'
 print ('</body>')
end

def show_error(message,back_page,tp)
 print('<div id="rmain"><div id="rmain2"><div id="rmain3">')
 print('<div class="main-title-nd">')
 print('<div class = "main-content">')
 print('<table border="0">')
 print('<TR><TD><img src = "../graphix/boom.gif"></TD>')
 print('<TD>')
 print(message)
 print('<BR>')
  case tp
    when 1
      print (back_page)
  end
 print('</TD></TR></TABLE></div></div></div></div></div>')
 end

 def file_suck_in (f_name)

   filename = TEXT_ROOT+f_name

 	if File.exists?(filename) 
 		IO.foreach(filename) { |line| line=line+"<br>" 
 		  line.gsub!(" ","&nbsp;")
 		  print(line) } 
 	else
 		print "<br>#{filename} has run away...please tell sysop!<br>"
 	end

 end

 def side_menu
   w_open_database
   groups = fetch_groups
   print ('<div id="side"><div id="side2">')

   print ('<h2 class="side-title">Menu:</h2>')
   print ('<div class ="side-datablock">')
   print ('<a href="email.rbx">Email</a><br>')
   print ('Message Groups')
   print ('<ul>')
   groups.each {|group| line = "<li><a href='areas.rbx?m_grp=#{group.number}'>#{group.groupname}</a></li>"
                print(line)}
   print ('</ul>')
   print ('Telnet:')
   print ('<ul>')
   print ('<li><a href="../java/bbs.html">BBS</a></li>')
   print ('<li><a href="../java/gd.html">Global Destruction</a></li>')   
   print ('</ul>') 
   print('<a href="about.rbx">About</a><br>')
   print('<a href="chat.rbx">Chat</a><br>')
   print('<a href="information.rbx">Information</a><br>')
   print('<a href="last.rbx">Last Callers</a><br>')
   print('<a href="users.rbx">User Listing</a><br>')
      print('<a href="log.rbx">System Log</a><br>')
   print('<a href="password.rbx">User Settings</a><br>')
   print('<a href="who.rbx">Who is Online</a><br><br>')
   print('<a href="logoff.rbx">Logout</a><br>')
    print '<img style="margin-top:15px" src="../graphix/ruby.jpg">'
   print('</div></div></div>')
   close_database
 end
 
  def scanforaccess(user)
    user.lastread = [] if user.lastread == nil
    user.areaaccess = [] if user.areaaccess == nil
    
  for i in 0..(a_total - 1) do
   area = fetch_area(i)
   user.lastread[i] = 0 if user.lastread[i] == nil 
   user.areaaccess[i] = area.d_access if user.areaaccess[i] == nil 
  end
  update_user(user,get_uid(user.name))
  return user
 end
 
  def qwk_kludge_search(msg_array)	#searches the message buffer for kludge lines and returns them

 tz		= nil
 msgid		= nil
 via		= nil
 reply		= nil




 msg_array.each_with_index {|x,i|
 	if x.slice(0) == 64 then
   x.slice!(0)
 	 match = (/^(\S*)(.*)/) =~ x
 
  	 if !match.nil? then 
  	  case $1
  	   when "MSGID:"
         msgid = $2.strip
         msg_array[i] = nil
       when "VIA:"
         via = $2.strip
         msg_array[i] = nil
       when "TZ:"
         tz = $2.strip
         msg_array[i] = nil
       when "REPLY:"
         reply = $2.strip
         msg_array[i] = nil
		  end
		 end
	end}


   msg_array.compact!	#Delete every line we marked with a nil, cause it had a kludge we caught!


 return [msg_array,msgid,via,tz,reply]
 end
 
  def fix_pointer(user,m_area)
   user.lastread = Array.new(2,0) if user.lastread == 0
   user.lastread[m_area] ||= 0 
   return user
 end
 
def h_msg(c_area)
 area = fetch_area(c_area)
 h_msg = m_total(area.tbl)
 return h_msg
end
	
def get_orig_address(msgid)
 orig = nil
 match = (/^(\S*)(\S*)/) =~ msgid.strip
 orig = $1 if !match.nil? 
 return orig
end

def pntr(user,c_area)
   area = fetch_area(c_area)
   p_msg = m_total(area.tbl) - new_messages(area.tbl,user.lastread[c_area])
  # print"user lastread: #{user.lastread[c_area]}<br>"
  # print "p_msg: #{p_msg}<br>m_total: #{m_total(area.tbl)}<br>new_messages: #{new_messages(area.tbl,user.lastread[c_area])}"
   p_msg = 1 if p_msg < 1
  # print "p_msg: #{p_msg}<BR>"
  return p_msg
 end
   