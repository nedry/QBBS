require "cgi"
require "cgi/session"
require "functions.rb"

cgi = CGI.new("html3")

print cgi.header("content"=>"text/html")



print_header

print '<div id="main-l"><div id="main2-l"><div id="main3-l">'
print '<div class="main-title">'
print '<h2 class = "w_header">Login</h2>'
print '</div>'
print '<div class = "main-content">'
print '<table  border="0">'
print '<form action="clogon.rbx" method="post">'
print '<tr>'
print '<td >Account Name</td>'
print '<td ><input name="acc_name" type="text" maxlength="50"></td>'
print '</tr>'
print '<tr>'
print '<td>Password</td>'
print '<td><input name="password" type="password" maxlength="50"></td>'
print '</tr>'
print '<tr><td colspan=2>'
print ' <input  name="login" type="submit" value="Login"> '
print '&nbsp;&nbsp;<a href="newuser.rbx"  title="Create new user"><button>New User</button></a>'
print '<a href="http://www.freedomain.co.nr/" target="_blank"><img style="margin-left:200px" src="http://smsorea.ckc.com.ru/but1.gif" width="88" height="31" border="0" alt="Free URL Redirection @ .co.nr" /></a>'

print '</td></tr>'

print '</form>'
print '</table>'
print '</div></div></div></div></div>'
print '<div style="clear:both"></div>'
print_footer
   

  
