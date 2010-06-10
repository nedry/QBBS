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

new_alias = cgi['chat_alias']

sess = CGI::Session.new( cgi, "session_key" => "qbbs_session",  
                                   "prefix" => "web-session.")
  

print_header
if !sess['name'].nil? then 
  name = sess['name']

  side_menu
  w_open_database
   user = fetch_user(get_uid(name))

  
   	newalias = new_alias.strip.split.to_s.slice(0..14)
	if newalias == user.alais then
	 show_error("That is already your alias.","Click <a href='password.rbx'>here</a> to try again." ,1)
	else
	if !alias_exists(newalias) then 
	  print('<DIV Id="main-l"><DIV Id="main2-l"><DIV ID="main3-l">')
          print('<DIV class = "main-content">')
	  user.alais = newalias
	  update_user(user,get_uid(user.name))
	  print 'Chat Alias Updated.<br>'
	else 
	 show_error("That alias is in use by another user.","Click <a href='password.rbx'>here</a> to try again." ,1)
	end
      end
      print('</div></div></div></div></div>')

  close_database
  sess.close
else
  show_error("You are not logged in.","<a href='logon.rbx'>Click here to logon.</a>",1)
end

print_footer
  
