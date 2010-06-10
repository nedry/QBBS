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

print_header

sess = CGI::Session.new( cgi, "session_key" => "qbbs_session",  
                                   "prefix" => "web-session.")
if !sess['name'].nil? then 
 uid=sess['uid']
 side_menu
 w_open_database
 who_list_update(uid,"About")
 close_database
print '<div id="main-l"><div id="main2-l"><div id="main3-l">'
print '<div class="main-title">'
print "<h2 class = 'w_header'>About #{TITLE}</h2>"
print '</div>'


print '<div class = "main-body">'
print '<h2 class="w_header">QBBS is a production of:</h2>'

print '<img src="../graphix/logo.gif"></center>'

print '<h2 class="w_header">Programmers:</h2>'

print '<UL>'

print '<LI><a href="mark.rbx">Mark Firestone</a></li>'
print '<LI>Martin Demello</LI>'
print '<LI><a href="http://www.yagni.com">Wayne Conrad</a></li>'
print '<LI>John Lorance</LI>'

print '</UL>'

print '<h2 class="w_header">Libraries:</h2>'
print '<UL>'
print '<LI><a href="http://www.modruby.net">Mod_Ruby</a></li>'
print '<LI><a href="http://ruby.scripting.ca/postgres/">Postgresql Library</a></li>'


print '</UL>'
print '</div></div></div></div></div>'

print_footer

  
end

