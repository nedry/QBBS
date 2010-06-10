require "cgi"
require "cgi/session"
require "pg"
require "/home/mark/qbbs2/db_user.rb"
require "functions.rb"
require "/home/mark/qbbs2/consts.rb"



cgi = CGI.new("html3")

print cgi.header("content"=>"text/html")

 print_header
 print('<DIV Id="hmain"><DIV Id="hmain2"><DIV ID="hmain3">')
 print('<DIV class = "main-content">')

  print('<font face="courier">')
  file_suck_in("newuser.txt")
  print('</font>')
  print('<a href="logon.rbx">Click To Agree and Log into the BBS.</a>')
  print('</div></div></div></div></div>')
  print_footer
