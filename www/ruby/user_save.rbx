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

def validate_user(username)

 happy = username.rindex(/[,*@:\']/)
 
  if happy.nil? then
   if !user_exists(username) then
    username.upcase!

    return username
   else
    show_error("Username Exists... ","<a href='newuser.rbx'>Try Again</a>",1)
    return nil
   end
  else
      show_error("User IDs must be between 3 and 25 characters, and may not contain...<br>the characters : * @ , ' ","<a href='newuser.rbx'>Try Again</a>",1)
 end
end

     
cgi = CGI.new("html3")

print cgi.header("content"=>"text/html")

username= cgi['username']
new_password = cgi["new_password"]
verify_password = cgi["verify_password"]
email = cgi['email']
location = cgi['location']


  


print_header

  w_open_database

  
 
       if (new_password.upcase.strip == verify_password.upcase.strip) and (new_password.length > 4) then
        happy = (/^(\S*)@(\S*)\.(\S*)/) =~ email
	 if !happy.nil? then 
	  if location.length > 5 then
	  user_to_make = validate_user(username)
	  if !user_to_make.nil? then
	   add_user(username,'000.000.000',new_password.upcase,location,email,24,80,true, true, DEFLEVEL, true) 
	   print('<DIV Id="main"><DIV Id="main2"><DIV ID="main3">')
	   print('<DIV class = "main-content">')
	   print ('Account Creation Successful.  Please <a href="new_usr_msg.rbx">Click Here</a> to read the User Agreement.')
	   print('</div></div></div></div></div>')
	  end

	  else
	   show_error("Invalid location.  Try again!","<a href='newuser.rbx'>Try Again</a>",1)
	  end
	 else 
	  show_error("Invalid E-mail address.  Try again!","<a href='newuser.rbx'>Try Again</a>",1)
	 end
       else
        if new_password.length < 5 then
	 show_error("Passwords must be at least 5 characters.  Try again!","<a href='newuser.rbx'>Try Again</a>",1)
	else
	 show_error("Passwords do not match.  Try again!","<a href='newuser.rbx'>Try Again</a>",1)
	end
       end

  close_database


print_footer
  
