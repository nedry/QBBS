require "cgi"
require "cgi/session"
require "pg"
require "/home/mark/qbbs2/db.rb"
require "/home/mark/qbbs2/db_class.rb"
require "/home/mark/qbbs2/db_user.rb"
require "/home/mark/qbbs2/db_groups.rb"
require "/home/mark/qbbs2/db_area.rb"
require "/home/mark/qbbs2/db_message.rb"
require "/home/mark/qbbs2/db_groups.rb"
require "functions.rb"
require "/home/mark/qbbs2/consts.rb"




cgi = CGI.new("html3")

print cgi.header("content"=>"text/html")

old_password = cgi['old_password']
new_password = cgi["new_password"]
verify_password = cgi["verify_password"]



sess = CGI::Session.new( cgi, "session_key" => "qbbs_session",  
                                   "prefix" => "web-session.")
  


print_header
if !sess['name'].nil? then 
  name = sess['name']

  side_menu
  w_open_database
   user = fetch_user(get_uid(name))


    
   
       print('<DIV Id="main"><DIV Id="main2"><DIV ID="main3">')
       print('<DIV class = "main-content">')
       if old_password.upcase.strip != user.password.strip then
         show_error("You must enter your correct current password!","<a href='password.rbx'>Try Again</a>",1)
       else 
       if new_password.upcase.strip == verify_password.upcase.strip then
        user.password = new_password.upcase.strip
	update_user(user,get_uid(user.name))
	print 'Password Updated.<br>'
       else
        show_error("Passwords do not match.  Try again!","<a href='password.rbx'>Try Again</a>",1)
       end
     end
       
      print('</div></div></div></div></div>')

  close_database
  sess.close
else
  show_error("You are not logged in.","<a href='logon.rbx'>Click here to logon.</a>",1)
end

print_footer
  
