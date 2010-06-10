require "cgi"
require "cgi/session"
require "pg"
require "/home/mark/qbbs2/db.rb"
require "/home/mark/qbbs2/db_class.rb"
require "/home/mark/qbbs2/db_user.rb"
require "/home/mark/qbbs2/db_groups.rb"
require "/home/mark/qbbs2/db_who.rb"
require "functions.rb"
require "/home/mark/qbbs2/consts.rb"



cgi = CGI.new("html3")

print cgi.header("content"=>"text/html")
grp = cgi['m_grp']
sess = CGI::Session.new( cgi, "session_key" => "qbbs_session", 
                                   "prefix" => "web-session.")
				   

 
print_header

if !sess['name'].nil? then 
  name = sess['name']
  uid= sess['uid']
  side_menu
  w_open_database
  who_list_update(uid,"Telnet.")
  print('<DIV Id="wmain"><DIV Id="wmain2"><DIV ID="wmain3">')
  print '<div class="main-title">'
  print "<h2 class = 'w_header'>Telnet:</h2>"
  print '</div>'

  print('<DIV class = "main-content">')

  user = fetch_user(get_uid(name))
 print('<applet CODEBASE="http://retrobbs.co.nr/ruby"  ARCHIVE="jta26.jar" CODE="de.mud.jta.Applet" WIDTH=580 HEIGHT=360>')
   print('<param name="config" value="simple.conf">')
	print('</div></div></div></div></div>')
  close_database
  sess.close
else
  show_error("You are not logged in.","<a href='logon.rbx'>Click here to logon.</a>",1)
end
print_footer


  
