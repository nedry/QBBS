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
  

uid=cgi['uid'].to_i


print_header
if !sess['name'].nil? then 
  name = sess['name']
  uid = sess['uid']

  side_menu
  w_open_database
   who_list_update(uid,"Chat.")
  user = fetch_user(get_uid(name))
  
  print('<DIV Id="main-l"><DIV Id="main2-l"><DIV ID="main3-l">')
  print "<div class='main-title'>"
  print "<h2 class = 'w_header'>BBS Chat</h2>"
  print '</div>'
  print '<div class = "main-body">'

  if user.alais.nil? then
   print("<p>You do not have an chat alias set. To set one click on <a href='password.rbx'>User Settings</a>.</p>" )
 else
  print '<p>Click chat to chat.  This will launch the our HTTP IRC client...</p>'
  print "<form name='cgiirclogin' method='post' onsubmit='return openCgiIrc(this, 0)' action='../chat/irc.cgi'>"
  print "<input type='hidden' name='interface' value='nonjs'>"
  print "<input type='hidden' name='Nickname' value='#{user.alais}'>"
  print "<input type='hidden' name='Server' value='irc.larryniven.org'>"
  print "<input type='hidden' name='Channel' value='#knownspace'>"
  print "<input type='submit' value='Login'>"
  print "</form>"

end
  print('</div></div></div></div></div>')
  close_database
  sess.close
else
  show_error("You are not logged in.","<a href='logon.rbx'>Click here to logon.</a>",1)
end

print_footer
  
