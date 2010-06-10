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




sess = CGI::Session.new( cgi, "session_key" => "qbbs_session",  
                                   "prefix" => "web-session.")

print_header

if !sess['name'].nil? then   uid = sess['uid']
  name = sess['name']


  side_menu
  w_open_database
  who_list_update(uid,"User Settings.")
  user = fetch_user(get_uid(name))
       print '<DIV Id="main-l"><DIV Id="main2-l"><DIV ID="main3-l">'
       print '<div class = "main-title">'
       print '<h3 class = "w_header">Change Password</h3>'
       print '</div>'
       print '<DIV class = "main-content">'
       print '<table border="0">'
       print '<td>'
       print '<FORM ACTION="password_save.rbx" METHOD="post"> '
       print ' <TR><TD>Old Password</td><td>'
       print '<input name="old_password" type="password" id="old_password">'
       print '</td></tr>'
       print ' <TR><TD>New Password</td><td>'
       print '<input name="new_passwordtd>'
       print '<input name="old_password" type="password" id="old_password">'
       print '</td></tr>'
       print ' <TR><TD>Verify Password</td><td>'
       print '<input name="verify_password" type="password" id="verify_password">'
       print '</td></tr>'
       print '<TR><TD>'
       print '<input type="submit" name="Submit" value="Save">'
       print '</form>'
       print '</table>'

       print '<div class = "main-title">'
 print '<h3 class = "w_header">Set Chat Alias</h3></div>'

       print '<table border="0">'
       print '<td>'
       print '<FORM ACTION="chat_save.rbx" METHOD="post"> '
       print ' <TR><TD>Chat Alias</td><td>'
       print("<input name='chat_alias' value='#{user.alais}' id='chat_alias'>")
       print '</td></tr>'
       print '<TR><TD>'
       print '<input type="submit" name="Submit" value="Save">'
       print '</form>'
       print '</table>'
       
       print('</div></div></div></div></div>')
# close_database
  sess.close
 
else
  show_error("You are not logged in.","<a href='logon.rbx'>Click here to logon.</a>",1)
end

print_footer
  
