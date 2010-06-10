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
grp = cgi['m_grp']
sess = CGI::Session.new( cgi, "session_key" => "qbbs_session", 
                                   "prefix" => "web-session.")
				   

 
print_header

if !sess['name'].nil? then 
  name = sess['name']
  uid = sess['uid']
  side_menu
  
 print('<DIV Id="main-l"><DIV Id="main2-l"><DIV ID="main3-l">')
 print('<DIV class = "main-content">')
   w_open_database
    who_list_update(uid,"Area List.")
    user = fetch_user(get_uid(name))
    user = scanforaccess(user)
    print('<table width = "80%">')
    print "Empty Message Group." if fetch_area_list(grp).length == 0 
    fetch_area_list(grp).each {|area|

  				  tempstr = (
  				  case user.areaaccess[area.number] 
  				   when "I"; "Invisible"
             when "R"; "Read"
             when "W"; "Write"
  				   when "N"; "None"
  				  end)
  				  
  				  if (user.areaaccess[area.number] != "I") or (user.level == 255) and (!area.delete) then
  				   l_read = new_messages(area.tbl,user.lastread[area.number])
  				   line = "<tr><td><a href='message.rbx?m_area=#{area.number}'>#{area.name}</a></td><td>#{l_read}</td><td>#{tempstr}</td></tr>"
  				   print(line)
  				  end
  				   }
		close_database
	 print('</table>')
	print('</div></div></div></div></div>')
  sess.close
else
  show_error("You are not logged in.","<a href='logon.rbx'>Click here to logon.</a>",1)
end
print_footer


  
