require "cgi"
require "cgi/session"
require "pg"
require "/home/mark/qbbs2/db_user.rb"
require "functions.rb"
require "/home/mark/qbbs2/consts.rb"



cgi = CGI.new("html3")

print cgi.header("content"=>"text/html")
sess = CGI::Session.new( cgi, "session_key" => "qbbs_session", 
                                   "prefix" => "web-session.")
print_header

if !sess['name'].nil? then 
 print('<DIV Id="hmain-l"><DIV Id="hmain2-l"><DIV ID="hmain3-l">')
 print('<DIV class = "main-content">')

  print('<font face="courier">')
  file_suck_in("welcome1.txt")
  print('</font>')
  print('<a href="main.rbx">Click To Enter</a>')
  print('</div></div></div></div></div>')
  sess.close
else
  show_error("You are not logged in.","<a href='logon.rbx'>Click here to logon.</a>",1)
end

print_footer
