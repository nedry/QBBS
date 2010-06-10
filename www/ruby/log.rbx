require "cgi"
require "cgi/session"
require "pg"
require "/home/mark/qbbs2/db.rb"
require "/home/mark/qbbs2/db_class.rb"
require "/home/mark/qbbs2/db_user.rb"
require "/home/mark/qbbs2/db_groups.rb"
require "/home/mark/qbbs2/db_log.rb"
require "/home/mark/qbbs2/db_who.rb"
require "/home/mark/qbbs2/db_who_telnet.rb"
require "functions.rb"
require "/home/mark/qbbs2/consts.rb"



cgi = CGI.new("html3")

dir = "f"
last = 0

D_MAX = 25

dir = cgi['dir'] if cgi['dir'] != ""

last = cgi['last'].to_i if cgi['last'] != 0


print cgi.header("content"=>"text/html")
grp = cgi['m_grp']
sess = CGI::Session.new( cgi, "session_key" => "qbbs_session", 
                                   "prefix" => "web-session.")
				   

 
print_header




if !sess['name'].nil? then 
  name = sess['name']
  uid= sess['uid']
  side_menu
  w_open_database
  
  if dir == "f" then
   stop = last + D_MAX
   stop = log_size-1 if stop >= log_size-1
  end
  
  if dir =="b" then
   stop = last -  D_MAX
   last = last - (D_MAX * 2)
   stop = 0 if stop < 0
 end
 



  who_list_update(uid,"System Log")
  print('<DIV Id="wmain"><DIV Id="wmain2"><DIV ID="wmain3">')
  print '<div class="main-title">'
  print "<h2 class = 'w_header'>System Log:</h2>"
  print '</div>'

  print('<DIV class = "main-content">')

   user = fetch_user(get_uid(name))
   
if stop-D_MAX > 0 then 
   print "<a href='log.rbx?last=#{stop}&dir=b'>Prev</a>&nbsp;&nbsp;&nbsp;"
end 

 if stop < log_size-1 then
   print "<a href='log.rbx?last=#{stop}&dir=f'>Next</a>"
 end
 
   print "<table cellspacing=5>"
   print "<tr><td><b>Date</b></td><td><b>Sub-system</b></td><td><b>Entry</b></td></tr>"
   arr = fetch_log(0)
   for i in last..stop
	  x = arr[i]
	  t= Time.parse(x[1]).strftime("%m/%d/%y %I:%M%p")

           print "<tr>"
         print "<td>#{t} </td><td>#{x[0]} </td><td>#{x[2]}</td></tr>"
	   end
   print "</table>"
 

 if stop-D_MAX > 0 then 
   print "<a href='log.rbx?last=#{stop}&dir=b'>Prev</a>&nbsp;&nbsp;&nbsp;"
end 

 if stop < log_size-1 then
   print "<a href='log.rbx?last=#{stop}&dir=f'>Next</a>"
 end
 

 
	print('</div></div></div></div></div>')
  close_database
  sess.close
else
  show_error("You are not logged in.","<a href='logon.rbx'>Click here to logon.</a>",1)
end
print_footer


  
