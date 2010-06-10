class CGI::Session
	def clear
		@data.clear
		@dbman.delete
		@dbprot.clear
	end
end



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

        254.chr => "&#9632"
}



	def parse_webcolor(str)
		#str = str.to_s.gsub("\t",'')
			WEBCOLORTABLE.each_pair {|color, result|
				str = str.gsub(color,result)
			}
		return str
	end
  
def print_header
 print('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">')
 print('<HEAD><TITLE> '+ TITLE + '</TITLE>')
 print('<link rel="stylesheet" type="text/css" href="../qbbs.css">')
 print('<body>')
 print('<DIV class="header">')
 print('<h3>QBBS V2.0 retroCOMPUTING BBS &nbsp;&nbsp;Job 1 &nbsp;&nbsp;KB0&nbsp;&nbsp; '+ CGI::rfc1123_date(Time.now)+'</h3>')
 print('</div>')
 print('<DIV class="main_frame">')
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
   