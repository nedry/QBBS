require "cgi"
require "cgi/session"
require "pg"
require "/home/mark/qbbs2/db.rb"
require "/home/mark/qbbs2/db_class.rb"
require "/home/mark/qbbs2/db_user.rb"
require "/home/mark/qbbs2/db_groups.rb"
require "/home/mark/qbbs2/db_who.rb"
require "/home/mark/qbbs2/db_who_telnet.rb"
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
  who_list_update(uid,"Who is Online.")
  print('<DIV Id="wmain"><DIV Id="wmain2"><DIV ID="wmain3">')
  print '<div class="main-title">'
  print "<h2 class = 'w_header'>Who's Online:</h2>"
  print '</div>'

  print('<DIV class = "main-content">')

  user = fetch_user(get_uid(name))
   print"<h3>Web Users:</h3>"
   print "<table cellspacing=5>"
   print "<tr><td><b>User ID</b></td><td><b>Location</b></td><td><b>Last Activity</b></td><td><b>Where</b></td></tr>"
  fetch_who_list.each {|x| 
           print "<tr>"
	   print "<td><a href='show_user.rbx?uid=#{x[0]}'>#{x[1]}</a>"
           print "<td>#{x[2]} </td><td>#{x[3].to_s} </td><td>#{x[4]}</td></tr>"
	   }
  print "</table>"
 
   print "<table cellspacing=5>"
   print"<h3>Telnet Users:</h3>"
   print "<tr><td><b>Node</b></td><td><b>User ID</b></td><td><b>Location</b></td><td><b>Where</b></td></tr>"
   fetch_who_t_list.each {|x| 
           print "<tr>"
	   print "<td>#{x[1]}"
           print "<td>#{x[5]} </td><td>#{x[2]} </td><td>#{x[3]}</td></tr>"
	   }
  print "</table>"
	print('</div></div></div></div></div>')
  close_database
  sess.close
else
  show_error("You are not logged in.","<a href='logon.rbx'>Click here to logon.</a>",1)
end
print_footer


  
