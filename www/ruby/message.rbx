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
sess = CGI::Session.new( cgi, "session_key" => "qbbs_session",  
                                   "prefix" => "web-session.")
  
def m_menu(m_area,pointer,dir,subject,from,total)
  print "<table><tr><td>"
  print("<B>Messages 1 - #{total} [</b>#{pointer}<b>]:</b></td> ") 

  print("<td><a href='message.rbx?m_area=#{m_area}&last=#{pointer}&dir=b'>Previous</a>&nbsp;&nbsp;")
	print("<a href='message.rbx?m_area=#{m_area}&last=#{pointer}&dir=f'>Next</a>&nbsp;&nbsp;")
	print("<a href='post.rbx?m_area=#{m_area}&subject=#{subject}&to=#{from}&last=#{pointer}&dir=f'>Reply</a>&nbsp;&nbsp;")
	print("<a href='post.rbx?m_area=#{m_area}&last=#{pointer}&dir=f'>Post</a>&nbsp;&nbsp;")
	print '</td><td><form action="message.rbx" method="post">'
        print "<input type='hidden' name='m_area' value='#{m_area}'>"
        print "<input type='hidden' name='dir' value='j'>"
        print "Jump: <input type='text' name = 'last' size='4' value=''></td></td></table>"
        print "</form>"
	print("<BR><BR>")

end

def w_display_message(mpointer,user,m_area,email,dir,total)
      area = fetch_area(m_area)
      table = area.tbl
      abs = absolute_message(table,mpointer)

      curmessage = fetch_msg(table, abs)
      m_menu(m_area,mpointer,dir,curmessage.subject.strip,curmessage.m_from.strip,total)
      if user.lastread[m_area] < curmessage.number then
       user.lastread[m_area] = curmessage.number
       update_user(user,get_uid(user.name))
      end
       message = []
       curmessage.msg_text.each('ã') {|line| message.push(line.chop!)}

      if curmessage.network then
       message,q_msgid,q_via,q_tz,q_reply = qwk_kludge_search(message)
      end
      #puts q_via
      print "<div class='fixed'>"
      print "##{mpointer} [#{curmessage.number}] #{curmessage.msg_date}"
      print " <span style='color:green'>[NETWORK MESSAGE]</span>" if curmessage.network
      print " [SMTP]" if curmessage.smtp
      print " [FIDONET MESSAGE]" if curmessage.f_network
      print " [EXPORTED]" if curmessage.exported and !curmessage.f_network and !curmessage.network
      print " [REPLY]" if curmessage.reply
      print "<br>"
      print "<table>"
      print "<tr><td> <span style='color:blue'>To:</span></td><td>#{curmessage.m_to}</td></tr>"
      print "<tr><td><span style='color:blue'>From:</span></td><td>  #{curmessage.m_from.strip}"
       out = ""
      if curmessage.f_network then 
       out = "UNKNOWN"
       if curmessage.intl != "" then
        if curmessage.intl.length > 1 then
         o_adr = curmessage.intl.split[1]
 	zone,net,node,point = parse_intl(o_adr)
         out = "#{zone}:#{net}/#{node}"
         out << ".#{point}" if !point.nil?
       end
       else out = get_orig_address(curmessage.msgid) end
       print " (#{out})" 
      end
      if curmessage.network then
       out = BBSID
       out = q_via if !q_via.nil?
       print " (#{out})"
      end
      print "</td></tr>"
      print "<tr><td><span style='color:blue'>Title: </span></td><td>#{curmessage.subject}</td></tr></table><br>"
        message.each {|line|
                              print "#{parse_webcolor(line)}<BR>"}
      print "</div>"
     print "<BR>"
 return [curmessage.m_from.strip,curmessage.subject.strip]
end

print_header

if !sess['name'].nil? then 
  name = sess['name']
  uid = sess['uid']

  side_menu

 print('<DIV Id="wmain"><DIV Id="wmain2"><DIV ID="wmain3">')
 print('<DIV class = "main-content">')
   w_open_database
    who_list_update(uid,"Reading Messages.")
    user = fetch_user(get_uid(name))
    user = fix_pointer(user,m_area)
    area=fetch_area(m_area)

     if (user.areaaccess[area.number] != "I") or (user.level == 255) and (!area.delete) then
     if last == 0 then
      pointer = pntr(user,m_area) 

      if h_msg(m_area) > 0 then

       from,subject = w_display_message(pointer,user,m_area,false,dir,h_msg(m_area)) 

      else print "No messages." end

      
    else      
    if m_total(area.tbl) > 0 then
     if dir == "j" then
      if last <= h_msg(m_area) and last > 0 and m_total(area.tbl) > 0 then
       from,subject = w_display_message(last,user,m_area,false,dir,h_msg(m_area))
      else
       print "Out of Range."
      end
     else
     if dir == "f" then 
       if last < h_msg(m_area) then
       pointer = last+1

       from,subject = w_display_message(pointer,user,m_area,false,dir,h_msg(m_area))
      else
       print ("Highest Message.")
       pointer = h_msg(m_area)
      end
      else
       if last > 1 then 
	pointer = last-1 

	from,subject = w_display_message(pointer,user,m_area,false,dir,h_msg(m_area))
       else
	print "Lowest Message"
	pointer = 1
       end
      end
      end

     else
      print "No Messages."
     end
    end
   end


	print "<BR>"
   m_menu(m_area,pointer,dir,subject,from,h_msg(m_area))
	print('</div></div></div></div></div>')
  close_database
  sess.close
else
  show_error("You are not logged in.","<a href='logon.rbx'>Click here to logon.</a>",1)
end

print_footer
  
