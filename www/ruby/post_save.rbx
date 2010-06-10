require "cgi"
require "cgi/session"
require "pg"
require "/home/mark/qbbs2/db.rb"
require "/home/mark/qbbs2/db_class.rb"
require "/home/mark/qbbs2/db_user.rb"
require "/home/mark/qbbs2/db_area.rb"
require "/home/mark/qbbs2/db_message.rb"
require "/home/mark/qbbs2/db_groups.rb"
require "/home/mark/qbbs2/wrap.rb"
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
msg_text=cgi['msg_text']


sess = CGI::Session.new( cgi, "session_key" => "qbbs_session",  
                                   "prefix" => "web-session.")
  


print_header
if !sess['name'].nil? then 
  name = sess['name']

  side_menu
  w_open_database
   user = fetch_user(get_uid(name))
    area=fetch_area(m_area)

     if (user.areaaccess[area.number] == "W") or (user.level == 255) and (!area.delete) then
   
       print('<DIV Id="main"><DIV Id="main2"><DIV ID="main3">')
       print('<DIV class = "main-content">')
       msg_to = msg_to[0..39] if msg_to.length > 40
       msg_subject = msg_subject[0..39] if msg_subject.length > 40
      # print("m_area: #{m_area}<BR>last #{last}<BR>dir: #{dir}<BR>to: #{msg_to} <BR> subject: #{msg_subject}")
      msg_text = WordWrapper.wrap(msg_text,79)
      msg_text.gsub!(10.chr,"")
      msg_text.gsub!(CR.chr,'ã')
      #print msg_text
      #msg_text.each_byte {|c| print c, " "}
      msg_date = Time.now.strftime("%m/%d/%Y %I:%M%p")
      absolute = add_msg(area.tbl,msg_to,name,msg_date,msg_subject,msg_text,false,false,false,nil,nil,nil,nil,false)
      print "Posted Absolute Message ##{absolute}<BR>"
      print("<a href='message.rbx?m_area=#{m_area}&last=#{last}&dir=#{dir}'>Return</a>&nbsp;&nbsp;")
      print('</div></div></div></div></div>')
     else
      print('You do not have access.')
     end
  close_database
  sess.close
else
  show_error("You are not logged in.","<a href='logon.rbx'>Click here to logon.</a>",1)
end

print_footer
  
