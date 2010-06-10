require "cgi"
require "cgi/session"
require "pg"
require "/home/mark/qbbs2/db.rb"
require "/home/mark/qbbs2/db_user.rb"
require "/home/mark/qbbs2/db_who.rb"
require "functions.rb"
require "/home/mark/qbbs2/consts.rb"

class CGI::Session    #you have to overload CGI::session becasue it's retarded and doesn't clear sessions.
	def clear
		@data.clear
		@dbman.delete
		@dbprot.clear
	end
end

cgi = CGI.new("html3")

print_header

print cgi.header("content"=>"text/html")

sess = CGI::Session.new( cgi, "session_key" => "qbbs_session", 
                                   "prefix" => "web-session.")
if !sess['name'].nil? then 
  name = sess['name']
  uid = sess['uid']

w_open_database

 uid = sess["uid"]

   begin
       sess.delete
       sess.clear
   rescue ArgumentError  # if no old session
   end
   

 show_error("You have logged off.","<a href='logon.rbx'>Click here to logon.</a>",1)
  who_list_delete(uid) #remove user from who's online list

else
  show_error("You are not logged in.","<a href='logon.rbx'>Click here to logon.</a>",1)
end
print_footer
sess.close