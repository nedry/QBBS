require "cgi"
require "cgi/session"
require "pg"
require "/home/mark/qbbs2/db.rb"
require "/home/mark/qbbs2/db_class.rb"
require "/home/mark/qbbs2/db_user.rb"
require "/home/mark/qbbs2/db_area.rb"
require "/home/mark/qbbs2/db_message.rb"
require "/home/mark/qbbs2/db_groups.rb"
require "/home/mark/qbbs2/db_who.rb"
require "functions.rb"
require "/home/mark/qbbs2/consts.rb"


cgi = CGI.new("html3")

print cgi.header("content"=>"text/html")


sess = CGI::Session.new( cgi, "session_key" => "qbbs_session",  
                                   "prefix" => "web-session.")
  

def fetch_user_list
 res = @db.exec("SELECT  name, citystate, number FROM users ORDER BY name") 
 result = result_as_array(res)
return result
end


print_header

if !sess['name'].nil? then 
  name = sess['name']
  uid = sess['uid']

  side_menu
  
  print('<DIV Id="wmain"><DIV Id="wmain2"><DIV ID="wmain3">')
  print '<div class="main-title">'
  print "<h2 class = 'w_header'>User List:</h2>"
  print '</div>'

  print('<DIV class = "main-content">')
    w_open_database
     who_list_update(uid,"User List.")
   print "<table>"
   print "<tr><td><b>User ID</b></td><td><b>Location</b></td></tr>"
  fetch_user_list.each {|x| 
           print "<tr>"
	   for i in 0..1 do
	          if i == 0 then 
		   print "<td><a href='show_user.rbx?uid=#{x[2]}'>#{x[0]}</a>"
		  else
		   print "<td>#{x[i]} </td>"
		  end
	   end
	   print "</tr>"}
  print "</table>"
 
	print('</div></div></div></div></div>')
  close_database
  sess.close
else
  show_error("You are not logged in.","<a href='logon.rbx'>Click here to logon.</a>",1)
end

print_footer
  
