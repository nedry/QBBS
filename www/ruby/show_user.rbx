require "cgi"
require "cgi/session"
require "pg"
require "/home/mark/qbbs2/db.rb"
require "/home/mark/qbbs2/db_class.rb"
require "/home/mark/qbbs2/db_user.rb"
require "/home/mark/qbbs2/db_area.rb"
require "/home/mark/qbbs2/db_message.rb"
require "/home/mark/qbbs2/db_groups.rb"
require "functions.rb"
require "/home/mark/qbbs2/consts.rb"


cgi = CGI.new("html3")

print cgi.header("content"=>"text/html")


sess = CGI::Session.new( cgi, "session_key" => "qbbs_session",  
                                   "prefix" => "web-session.")
  

uid=cgi['uid'].to_i


print_header
if !sess['name'].nil? then 
  name = sess['name']

  side_menu
  w_open_database
  user = fetch_user(uid)
  
  print('<DIV Id="wmain"><DIV Id="wmain2"><DIV ID="wmain3">')
  print '<div class="main-title">'
  print "<h2 class = 'w_header'>User Details: #{user.name}</h2>"
  print '</div>'

  print('<DIV class = "main-content">')
  print '<table>'
  print "<tr><td>email:</td><td>#{user.address}</td></tr>"
  print "<tr><td>location:</td><td>#{user.citystate}</td></tr>"
  print "<tr><td>last on:</td><td>#{user.laston}</td></tr>"
  print "<tr><td>access level:</td><td>#{user.level}</td></tr>"
  print "<tr><td>chat alias:</td><td>#{user.alais}</td></tr>"
  print '</table>'
   
 
	print('</div></div></div></div></div>')
  close_database
  sess.close
else
  show_error("You are not logged in.","<a href='logon.rbx'>Click here to logon.</a>",1)
end

print_footer
  
