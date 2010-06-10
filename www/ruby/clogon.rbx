require "cgi"
require "cgi/session"
require "pg"
require "/home/mark/qbbs2/db.rb"
require "/home/mark/qbbs2/db_user.rb"
require "/home/mark/qbbs2/db_who.rb"
require "functions.rb"
require "/home/mark/qbbs2/consts.rb"



cgi = CGI.new("html3")

print cgi.header("content"=>"text/html")

name = cgi["acc_name"]
password = cgi["password"]




name.upcase! if !name.nil?
password.upcase! if !password.nil?

w_open_database

if user_exists(name) then 
 if check_password(name,password) then
  print "<br>Logging you on..."
   begin
       sess = CGI::Session.new(cgi, "session_key" => "qbbs_session", 
                                        'new_session' => false)
       sess.delete
   rescue ArgumentError  # if no old session
   end
   
   sess = CGI::Session.new( cgi, "session_key" => "qbbs_session", 
                                                  "session_id"  => "9650",
                                                  "new_session" => true, 
                                                  "prefix" => "web-session.")
   sess["name"] = name
   uid = get_uid(name) 
   sess["uid"] = uid

  who_list_add(uid) #add user to the list of web users online
  print cgi.header({'Status' => '302 Moved', 'location' =>'welcome.rbx'})
   sess.close

 else
  print_header
  show_error("Wrong Password","<a href='logon.rbx'>Try Again</a>",1)
 end
else
 print_header
 show_error("That User does not exist.","<a href='logon.rbx'>Click new to create a new user.</a>",1)
end

print_footer

