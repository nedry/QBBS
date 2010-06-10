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
to = cgi["to"]
subject=cgi["subject"]


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

   area=fetch_area(m_area)

     if (user.areaaccess[area.number] == "W") or (user.level == 255) and (!area.delete) then
  #     print('<DIV Id="hmain-l"><DIV Id="hmain2-l"><DIV ID="hmain3-l">')
        print('<DIV Id="wmain"><DIV Id="wmain2"><DIV ID="wmain3">')
       print('<DIV class = "main-content">')
       reply = ""
        if to !="" then 
	       curmessage = fetch_msg(area.tbl,absolute_message(area.tbl,last))
	       curmessage.msg_text.gsub!(10.chr,'')
	       reply = curmessage.msg_text.split(227.chr)
	        if curmessage.network then
	         reply,q_msgid,q_via,q_tz,q_reply = qwk_kludge_search(reply)
          end
        end
 
          print "<table>"
          print "<form name='main' method='post' action='post_save.rbx'>" 
          print "<input name='dir' type='hidden'  value='#{dir}'>" 
          print "<input name='last' type='hidden' value='#{last}'>" 
          print "<input name='m_area' type='hidden' value='#{m_area}'>"
          
	     if to != "" then
	      print "<input name='msg_to' type='hidden' value='#{to}'>"
	     end
          print "<tr><td>From: </td> <td>#{name}</td></tr>" 
          print "<tr><td>To:</td>"
          if to == "" then 
           print "<td><input name='msg_to' type='text' id='msg_to'>" 
          else 
           print "<td>#{to}"
          end
          print "</td></tr>" 
          print "<tr><td>Subject:</td><td><input name='msg_subject' type='text' id='msg_subject' value='#{subject}'></td></tr>"
          print "#{CRLF}"
          print "<tr><td colspan=2><textarea name='msg_text' cols='79' rows='25'  id='msg_text'>#{CRLF}"
          if to != "" then 
           print ("--- #{to} wrote --- #{CRLF}")
           reply.each {|line| print "&gt; #{line[0..75]}#{CRLF}"}
          end
    
               
          print"</textarea></td>" 
          print "</tr>"
          print "<tr>" 
          print "<td>&nbsp;</td>" 
          print "<td><input type='submit' name='Submit' value='Post'>" 
          print "<input type='reset' name='Reset' value='Reset Form'> </td>" 
          print "</tr>" 
          print "</form>" 
	  print "</table>"
	        print('</div></div></div></div>')
     else
      print('You do not have access.')
     end
  close_database
  sess.close
else
  show_error("You are not logged in.","<a href='logon.rbx'>Click here to logon.</a>",1)
end

print_footer
  
