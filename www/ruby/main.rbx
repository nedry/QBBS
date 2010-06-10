require "cgi"
require "cgi/session"
require "pg"
require "/home/mark/qbbs2/db.rb"
require "/home/mark/qbbs2/db_class.rb"
require "/home/mark/qbbs2/db_user.rb"
require "/home/mark/qbbs2/db_area.rb"
require "/home/mark/qbbs2/db_groups.rb"
require "functions.rb"
require "/home/mark/qbbs2/consts.rb"



cgi = CGI.new("html3")

print cgi.header("content"=>"text/html")
sess = CGI::Session.new( cgi, "session_key" => "qbbs_session", 
                                   "prefix" => "web-session.")

print_header

if !sess['name'].nil? then 
  side_menu
  sess.close
else
  show_error("You are not logged in.","<a href='logon.rbx'>Click here to logon.</a>",1)
end

print_footer
  
