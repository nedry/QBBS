require "cgi"
require "cgi/session"
require "functions.rb"

cgi = CGI.new("html3")

print cgi.header("content"=>"text/html")



print_header

print '<div id="main"><div id="main2"><div id="main3">'
print '<div class="main-title">'
print '<h2 class = "w_header">New User</h2>'
print '</div>'
print '<div class = "main-content">'
print 'Enter the following information to create a new user account.<br>'
print 'Please read and agree to the systems policies.<br><br>'
print '<table  border="0">'
print '<form action="user_save.rbx" method="post">'
print '<tr>'
print '<td >Account Name</td>'
print '<td ><input name="username" type="text" maxlength="50"></td>'
print '</tr>'
print '<tr>'
print '<td>Password</td>'
print '<td><input name="new_password" type="password" maxlength="40"></td>'
print '</tr>'
print '<tr>'
print '<td>Verify Password</td>'
print '<td><input name="verify_password" type="password" maxlength="40"></td>'
print '</tr>'
print '<tr>'
print '<td>Email Address</td>'
print '<td><input name="email" type="text" maxlength="40"></td>'
print '</tr>'
print '<tr>'
print '<td>Location</td>'
print '<td><input name="location" type="text" maxlength="40"></td>'
print '</tr>'
print '<tr><td></td></tr><tr><td>'
print '<input name="login" type="submit" value="Create">'
print '</td></tr>'

print '</form>'
print '</table>'
print '</div></div></div></div></div>'
print_footer
   

  
