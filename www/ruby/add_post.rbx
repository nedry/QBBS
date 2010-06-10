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

m_area = cgi['m_area']
m_area = m_area.to_i
last = cgi["last"]
last = last.to_i
dir = cgi["dir"]
dir = "+" if dir == ""
msg_to = cgi["msg_to"]
msg_subject=cgi["msg_subject"]


sess = CGI::Session.new( cgi, "session_key" => "qbbs_session",  
                                   "prefix" => "web-session.")
  


print_header
if !sess['name'].nil? then 
  name = sess['name']
  uid = sess['uid']

  side_menu
  w_open_database
   who_list_update(uid,"Posting a Message.")
   user = fetch_user(get_uid(name))
    print('<table width = "80%">')
   area=fetch_area(m_area)

     if (user.areaaccess[area.number] == "W") or (user.level == 255) and (!area.delete) then
       print("m_area: #{m_area}<br> last: #{last} <br> dir: #{dir} <br> to: #{to} <br> subject: #{subject}")
   
       print('<DIV Id="hmain"><DIV Id="hmain2"><DIV ID="hmain3">')
       print('<DIV class = "main-content">')
       print("m_area: #{m_area}<BR>last #{last}<BR>dir: #{dir}<BR>to: #{msg_to} <BR> subject: #{msg_subject}"
       
       print('</div></div></div></div></div>')
     else
      print('You do not have access.')
     end
  close_database
  sess.close
else
  show_error("You are not logged in.","<a href='logon.rbx'>Click here to logon.</a>",1)
end


  
