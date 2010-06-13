require 'rubygems'
require 'sinatra'
require 'haml'
require "pg_ext"

require "ansi.rb"
require "../db.rb"
require "../db/db_class.rb"
require "../db/db_area.rb"
require "../db/db_email.rb"
require "../db/db_user.rb"
require "../db/db_message.rb"
require "../db/db_who.rb"
require "../db/db_wall.rb"
require "../db/db_groups.rb"
require "../db/db_bulletins.rb"
require "../consts.rb"


 enable :sessions

TEXT_ROOT = "/home/mark/qbbs/text/"
TITLE = "QUARKseven Web v.01"

helpers do

  def partial(name, options = {})
    item_name = name.to_sym
    counter_name = "#{name}_counter".to_sym
    if collection = options.delete(:collection)
      collection.enum_for(:each_with_index).collect do |item, index|
        partial(name, options.merge(:locals => { item_name => item, counter_name => index + 1 }))
      end.join

    elsif object = options.delete(:object)
      partial name, options.merge(:locals => {item_name => object, counter_name => nil})
    else
      haml "_#{name}".to_sym, options.merge(:layout => false)
    end
  end
end

def who_list_add (uid)
  if !who_exists(uid) then
     add_who(uid,Time.now,"Logging in...")
  else 
     update_who(uid,Time.now,"Logging in again...")
 end
end

def who_list_delete (uid)
 if who_exists(uid) then
  delete_who(uid)
 end
 end

 
 def who_list_update(uid,loc)

   update_who(uid,Time.now,loc)
    who_list_check
    if !who_exists(uid) then
      add_who(uid,Time.now,loc)
    end
 end
 
 def text_to_html (f_name)

   filename = TEXT_ROOT+f_name
   output = ""

 	if File.exists?(filename) 
		output << "<br>"
 		IO.foreach(filename) { |line| line=line+"<br>" 
 		  line = parse_webcolor(line)
 		  output << line } 
 	else
 		output =  "<br>#{filename} has run away...please tell sysop!<br>"
 	end
   return output
 end

  def fix_pointer(user,m_area)
   user.lastread = Array.new(2,0) if user.lastread == nil or user.lastread == 0
   user.lastread[m_area] ||= 0 
   return user
 end
 
def w_scanformail(uid)
  
  user = fetch_user(uid.to_i)
  user = fix_pointer(user,0)
  area = fetch_area(0)

  hash = email_lookup_table(area.tbl,user.name)
  total =  e_total(area.tbl,user.name)
  pointer = find_epointer(hash,user.lastread[0],area.tbl,user.name) 
  if pointer != nil then  
   if total > pointer then	
    return true #new mail
   end
  end
  return false #no new mail
 end

def close_database
  @db.close
end

def side_menu_gubbins
 groups = fetch_groups
 name = session[:name]
 uid = get_uid(name)

    if w_scanformail(uid) then
    e_out = '<a href="/email">Email (New!)</a><br>'
   else
     e_out = '<a href="/email">Email</a><br>'
   end
   
   g_out = ""
      groups.each {|group| line = "<li><a href='/areas?m_grp=#{group.number}'>#{group.groupname}</a></li>"
              g_out << (line)}
 return [e_out,g_out]
end

  def scanforaccess(user)
    user.lastread = [] if user.lastread == nil
    user.areaaccess = [] if user.areaaccess == nil
    
  for i in 0..(a_total - 1) do
   area = fetch_area(i)
   user.lastread[i] = 0 if user.lastread[i] == nil 
   user.areaaccess[i] = area.d_access if user.areaaccess[i] == nil 
  end
  update_user(user,get_uid(user.name))
  return user
 end
 
 
def area_list_gubbins(grp)
    o_area = ""
    group = fetch_groups

    o_name = group[grp.to_i - 1].groupname
    user = fetch_user(get_uid(session[:name]))
    user = scanforaccess(user)
    o_area = '<table width = "80%" style="margin-left:10px">'
    o_area =  "&nbsp;&nbsp;&nbsp;Empty Message Group." if fetch_area_list(grp).length == 0 
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
  				   o_area << "<tr><td><a href='/message?m_area=#{area.number}'>#{area.name}</a></td><td>#{l_read}</td><td>#{tempstr}</td></tr>"
  				   
  				  end
  				   }
	o_area << "</table>"
  return o_area,o_name
end

def m_menu(m_area,pointer,dir,subject,from,total)
  m_out = ""
  m_out << "<table><tr><td><B>Messages 1 - #{total} [</b>#{pointer}<b>]:</b></td> "
  m_out << "<td><a href='/message?m_area=#{m_area}&last=#{pointer}&dir=b'>Previous</a>&nbsp;&nbsp;"
  m_out << "<a href='/message?m_area=#{m_area}&last=#{pointer}&dir=f'>Next</a>&nbsp;&nbsp;"
  m_out << "<a href='/post?m_area=#{m_area}&subject=#{subject}&to=#{from}&last=#{pointer}&dir=f'>Reply</a>&nbsp;&nbsp;"
  m_out << "<a href='/post?m_area=#{m_area}&last=#{pointer}&dir=f'>Post</a>&nbsp;&nbsp;"
  m_out <<  '</td><td><form action="/message" method="post">'
  m_out <<  "<input type='hidden' name='m_area' value='#{m_area}'>"
  m_out <<  "<input type='hidden' name='dir' value='j'>"
  m_out <<  "Jump: <input type='text' name = 'last' size='4' value=''></td></td></table>"
  m_out <<  "</form><BR><BR>"
  return m_out
end

def w_display_message(mpointer,user,m_area,email,dir,total)
      area = fetch_area(m_area)
      table = area.tbl
      abs = absolute_message(table,mpointer)
      m_out = ""
      curmessage = fetch_msg(table, abs)
      m_out << m_menu(m_area,mpointer,dir,curmessage.subject.strip,curmessage.m_from.strip,total)
      if user.lastread[m_area] < curmessage.number then
       user.lastread[m_area] = curmessage.number
       update_user(user,get_uid(user.name))
      end
       message = []
      # curmessage.msg_text.each('�') {|line| message.push(line.chop!)}

      if curmessage.network then
       message,q_msgid,q_via,q_tz,q_reply = qwk_kludge_search(message)
      end
      #puts q_via
      m_out << "<div class='fixed' style='background-color:black;color:white'>"
      m_out << "##{mpointer} <span style='color:#54fc54'>[</span><span style='color:#54fcfc'>#{curmessage.number}</span><span style='color:#54fc54'>]</span> <span style='color:#5454fc'>#{curmessage.msg_date}</span>"
      m_out <<  " <span style='color:#54fc54'> [NETWORK MESSAGE]</span>" if curmessage.network
      m_out << " [SMTP]" if curmessage.smtp
      m_out << "<span style='color:#54fc54'> [FIDONET MESSAGE]</span>" if curmessage.f_network
      m_out << "<span style='color: #fcfc54'> [EXPORTED]</span>" if curmessage.exported and !curmessage.f_network and !curmessage.network
      m_out << " [REPLY]" if curmessage.reply
      m_out << "<br>"
      m_out << "<table>"
      m_out << "<tr><td> <span style='color:#54fcfc'>To:</span></td><td><span style='color:#54fc54'>#{curmessage.m_to}</span></td></tr>"
      m_out << "<tr><td><span style='color:#54fcfc'>From:</span></td><td><span style='color:#54fc54'>#{curmessage.m_from.strip}</span>"
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
       m_out << " (#{out})" 
      end
      if curmessage.network then
       out = BBSID
       out = q_via if !q_via.nil?
       m_out << " <span style='color:#54fc54'>(</span><span style='color:#54fcfc'>#{out}</span><span style='color:#54fc54'>)</span>"
      end
      m_out << "</td></tr>"
      m_out << "<tr><td><span style='color:#54fcfc'>Title: </span></td><td>#{curmessage.subject}</td></tr></table><br>"
      m_out << "<div id='msg'>"
      m_out << "#{parse_webcolor(curmessage.msg_text)}"
      m_out << "</div></div>"
     m_out << "<BR>"
 return [curmessage.m_from.strip,curmessage.subject.strip,m_out]
end

def pntr(user,c_area)
   area = fetch_area(c_area)
   p_msg = m_total(area.tbl) - new_messages(area.tbl,user.lastread[c_area])
  # print"user lastread: #{user.lastread[c_area]}<br>"
  # print "p_msg: #{p_msg}<br>m_total: #{m_total(area.tbl)}<br>new_messages: #{new_messages(area.tbl,user.lastread[c_area])}"
   p_msg = 1 if p_msg < 1
  # print "p_msg: #{p_msg}<BR>"
  return p_msg
 end
 
 def h_msg(c_area)
 area = fetch_area(c_area)
 h_msg = m_total(area.tbl)
 return h_msg
end

get '/' do
	
graphfile =  "welcome1.ans"
 plainfile =  "welcome1.txt"

 t_file = ROOT_PATH + TEXTPATH + "welcome1.ans"

 test = File.exists?(t_file) ? graphfile : plainfile
	
  haml :index, :locals => {:display_text => text_to_html(test)}
end

get "/information" do

if !session[:name].nil? then
  open_database
  name = session[:name]
  uid = get_uid(name)
  who_list_update(uid,"Information:")
  b_out = ""
  b_out << "<table cellspacing='5'>"
   for i in 1..(b_total)
    bulletin = fetch_bulletin(i)
    b_out << "<tr><td><a href='/bulletin?bull=#{i}'>#{bulletin.name}</a><br></tr>"
   end
   b_out << "</table>"
   e_out,g_out = side_menu_gubbins    #make the side menu database inserts on the sinatra side, like the manual says
   close_database
   haml :information, :locals => {:email => e_out, :groups => g_out, :bulletin => b_out}
  else 
   haml :notlogged
  end
 end

get "/last" do

if !session[:name].nil? then
  open_database
  wall_cull
  name = session[:name]
  uid = get_uid(name)
  who_list_update(uid,"Last Callers:")
  l_out = ""
  l_out << "<table cellspacing='5'>"
  l_out <<  "<tr><td><b>User ID</b></td><td><b>Date</b></td><td><b>Connection</td></tr>"
  
   fetch_wall.each {|x|
                               t= Time.parse(x[1]).strftime("%m/%d/%y %I:%M%p")
                               l_out << "<tr><td>#{x[0]}</td><td>#{t}</td><td>#{x[3]}</td></tr>"}
   l_out << "</table>"
   e_out,g_out = side_menu_gubbins    #make the side menu database inserts on the sinatra side, like the manual says
   close_database
   haml :last, :locals => {:email => e_out, :groups => g_out, :last => l_out}
  else 
   haml :notlogged
  end
 end


get '/about' do
  haml :about, :locals =>{:title => TITLE}
end

post '/clogon' do
  open_database
  happy =""
  name = params["acc_name"]
  passwd = params["password"].upcase
  if user_exists(name) then 
   if check_password(name,passwd) then
     session[:name] = name
     close_database
     redirect "/welcome"
   else
     close_database
     haml :failure
  end
end
end

get '/goodbye' do
  session[:name] = nil
  haml :goodbye  
end

get '/welcome' do
  graphfile =  "welcome2.ans"
   plainfile =  "welcome2.txt"

 t_file = ROOT_PATH + TEXTPATH + "welcome2.ans"

 test = File.exists?(t_file) ? graphfile : plainfile
 if !session[:name].nil? then
   haml :welcome,  :locals => {:display_text => text_to_html(test)}
 else
   haml :notlogged
 end
end

get '/bulletin' do


 if !session[:name].nil? then
  open_database
  name = session[:name]
  uid = get_uid(name)
  who_list_update(uid,"Reading Bulletins")
   number = params["bull"].to_i
   bulletin = fetch_bulletin(number)
   
   graphfile =  bulletin.path + ".gra"
 plainfile =  bulletin.path + ".txt"
 
 graphfile.untaint
 plainfile.untaint
 t_file = ROOT_PATH + TEXTPATH + bulletin.path + ".gra"
 t_file.untaint
 test = File.exists?(t_file) ? graphfile : plainfile

  e_out,g_out = side_menu_gubbins    #make the side menu database inserts on the sinatra side, like the manual says
  close_database
   haml :bulletin,  :locals => {:email => e_out, :groups => g_out,:display_text => text_to_html(test)}
 else
   haml :notlogged
 end
end

get "/areas" do
 
if !session[:name].nil? then
  open_database
  grp = params["m_grp"]
  name = session[:name]
  uid = get_uid(name)
  who_list_update(uid,"Area List.")
  a_out,n_out = area_list_gubbins(grp)
  e_out,g_out = side_menu_gubbins    #make the side menu database inserts on the sinatra side, like the manual says
  close_database
  haml :areas, :locals => {:email => e_out, :groups => g_out, :areas => a_out, :g_name => n_out}
 else 
   haml :notlogged
 end

end

get "/message" do

if !session[:name].nil? then
  open_database
  grp = params["m_grp"]
  m_area = params['m_area']
  m_area = m_area.to_i
  last = params["last"]
  last = last.to_i
  dir = params["dir"]
  name = session[:name]
  uid = get_uid(name)
  who_list_update(uid,"Reading Messages.")
   user = fetch_user(get_uid(name))
   user = fix_pointer(user,m_area)
   area=fetch_area(m_area)
   m_out = ""

     if (user.areaaccess[area.number] != "I") or (user.level == 255) and (!area.delete) then
     if last == 0 then
      pointer = pntr(user,m_area) 

      if h_msg(m_area) > 0 then

       from,subject,tempstr = w_display_message(pointer,user,m_area,false,dir,h_msg(m_area)) 
       m_out << tempstr
      else m_out << "No messages." end

      
    else      
    if m_total(area.tbl) > 0 then
     if dir == "j" then
      if last <= h_msg(m_area) and last > 0 and m_total(area.tbl) > 0 then
       from,subject,tempstr = w_display_message(last,user,m_area,false,dir,h_msg(m_area))
       m_out << tempstr
      else
       m_out << "Out of Range."
      end
     else
     if dir == "f" then 
       if last < h_msg(m_area) then
       pointer = last+1

       from,subject,tempstr = w_display_message(pointer,user,m_area,false,dir,h_msg(m_area))
       m_out << tempstr
      else
      m_out << "Highest Message."
       pointer = h_msg(m_area)
      end
      else
       if last > 1 then 
	pointer = last-1 

	from,subject,tempstr = w_display_message(pointer,user,m_area,false,dir,h_msg(m_area))
	m_out << tempstr
       else
	m_out << "Lowest Message"
	pointer = 1
       end
      end
      end

     else
      m_out << "No Messages."
     end
    end
  end


	m_out << "<BR>"
        m_out << m_menu(m_area,pointer,dir,subject,from,h_msg(m_area))
 
  e_out,g_out = side_menu_gubbins    #make the side menu database inserts on the sinatra side, like the manual says
  close_database
  haml :message, :locals => {:email => e_out, :groups => g_out, :message => m_out}
 else 
   haml :notlogged
 end

end

get "/main" do

if !session[:name].nil? then
  open_database
  name = session[:name]
  uid = get_uid(name)
  who_list_update(uid,"Main Menu.")
  e_out,g_out = side_menu_gubbins    #make the side menu database inserts on the sinatra side, like the manual says
  close_database
  haml :main, :locals => {:email => e_out, :groups => g_out, :name => name}
 else 
   haml :notlogged
 end
end