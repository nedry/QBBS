$LOAD_PATH << ".."
$LOAD_PATH << "."
require 'rubygems'
require 'socket'
require 'sinatra'
require 'haml'

require 'dm-core'
require 'dm-validations'

require "ansi.rb"

require "../db/db_area.rb"
require "../db/db_user.rb"
require "../db/db_message.rb"
require "../db/db_who.rb"
require "../db/db_wall.rb"
require "../db/db_groups.rb"
require "../db/db_bulletins.rb"
require "../db/db_log.rb"
require "../db/db_who_telnet.rb"
require "../db/db_system.rb"
require "../tools.rb"
require "../consts.rb"
require "../class.rb"
require "../wrap.rb"
require "../fortune.rb"



TEXT_ROOT = "/home/mark/qbbs/text/"
TITLE = "QUARKseven Web v.85"
EXISTS = 1
INVALID = 2
OKAY = 3

configure do
  enable :sessions
  set :static, true
  BasicSocket.do_not_reverse_lookup = true
  DataMapper::Logger.new('log/db', :debug)
  DataMapper.setup(:default, "postgres://#{DATAIP}/#{DATABASE}")
end

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



def get_or_post(path, opts={}, &block)
  get(path, opts, &block)
  post(path, opts, &block)
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

def determine_email_type(inp)

  to,zone,net,node,point = netmailadr(inp)
  if !to.nil? then
    return F_NETMAIL
  end
  to,route = qwkmailadr(inp)
  if !to.nil? then
    return Q_NETMAIL
  end
  smtp = stmpmailadr(inp)
  if smtp then
    return SMTP
  end
  return nil
end

def who_list_update(uid,loc)


  update_who(uid,Time.now,loc)  if who_exists(uid)
  who_list_check
  if !who_exists(uid) then
    add_who(uid,Time.now,loc)
  end
end

def text_to_html (f_name,user)

  filename = TEXT_ROOT+f_name
  output = ""

  if File.exists?(filename)
    output << "\n<pre>"
    IO.foreach(filename, :external_encoding=>"ASCII-8BIT") { |line| #line=line+"\n"
      line = parse_text_commands(line,user) if !user.nil?
      line = parse_webcolor(line)
    output << line }
    output <<"</pre>"
  else
    output =  "<br>#{filename} has run away...please tell sysop!<br>"
  end
  return output
end


def side_menu_gubbins
  groups = fetch_groups
  area = fetch_area(0)
  name = session[:name]
  uid = get_uid(name)
  u = fetch_user(uid.to_i)
  scanforaccess(u)
  pointer = get_pointer(u,0)


  new = new_email(pointer.lastread,u.name)

  if new > 0  then
    e_out = "<a href='/email'>Email (#{new} New!)</a><br>"
  else
    e_out = '<a href="/email">Email</a><br>'
  end

  if new_pages(u) > 0 then
    e_out << "<a href='/page'>Page (#{new_pages(u)} New!)</a><br>"
  else
    e_out <<'<a href="/page">Page</a><br>'
  end

  g_out = ""
  scanforaccess(u)
  groups.each {|group| line = "<li><a href='/areas?m_grp=#{group.grp}'>#{group.groupname}</a></li>"
  g_out << (line)}
  return [e_out,g_out]
end

def area_list_gubbins(grp)
  o_area = ""
  group = fetch_groups

  o_name = group[grp.to_i - 1].groupname
  user = fetch_user(get_uid(session[:name]))
  scanforaccess(user)
  o_area = '<table width = "80%" style="margin-left:10px">'
  o_area =  "&nbsp;&nbsp;&nbsp;Empty Message Group." if fetch_area_list(grp).length == 0
  fetch_area_list(grp).each {|area|
    tempstr = (
    pointer = get_pointer(user,area.number)
    case pointer.access
    when "I"; "Invisible"
    when "R"; "Read"
    when "W"; "Write"
    when "N"; "None"
    end)

    if (pointer.access != "I") or (user.level == 255) and (!area.delete) then
      l_read = new_messages(area.number,pointer.lastread)
      o_area << "<tr><td><a href='/message?m_area=#{area.number}'>#{area.name}</a></td><td>#{l_read}</td><td>#{tempstr}</td></tr>"

    end
  }
  o_area << "</table>"
  return o_area,o_name
end

def m_menu(m_area,pntr,dir,subject,from,total,email)
  m_out = ""
  abs = 0
  abs =absolute_message(m_area,pntr) if pntr > 0

  t_out = "/message"
  e_out = "Post"
  ptv = ""
  if email then
    t_out = "/email"
    e_out = "Email"
    pvt = "&pvt=t"
  end

  m_out << "<span style='background:white;color:black'><table><tr><td><B>Messages 1 - #{total} [</b>#{pntr}<b>]:</b></td> "
  m_out << "<td><a href='#{t_out}?m_area=#{m_area}&last=#{pntr}&dir=b'>Previous</a>&nbsp;&nbsp;"
  m_out << "<a href='#{t_out}?m_area=#{m_area}&last=#{pntr}&dir=f'>Next</a>&nbsp;&nbsp;"
  m_out << "<a href='/post?m_area=#{m_area}&subject=#{subject}&to=#{from}&last=#{pntr}&dir=f#{pvt}'>Reply</a>&nbsp;&nbsp;"
  m_out << "<a href='/delete?abs=#{abs}&area=#{m_area}'>Delete</a>&nbsp;&nbsp;"
  m_out << "<a href='/post?m_area=#{m_area}&last=#{pntr}&dir=f#{pvt}'>#{e_out}</a>&nbsp;&nbsp;"
  m_out << "<a href='/post?m_area=#{m_area}&subject=#{subject}&to=#{from}&last=#{pntr}&dir=f&pvt=t'>Email Reply</a>&nbsp;&nbsp;" if !email
  m_out <<  "</td><td><form action='#{t_out}' method='post'>"
  m_out <<  "<input type='hidden' name='m_area' value='#{m_area}'>"
  m_out <<  "<input type='hidden' name='dir' value='j'>"
  m_out <<  "Jump: <input type='text' name = 'last' size='4' value=''></td></td></table>"
  m_out <<  "</form></span><BR><BR>"
  return m_out
end


def w_display_message(mpointer,user,m_area,email,dir,total)
  area = fetch_area(m_area)
  pointer = get_pointer(user,m_area)
  group = fetch_group_grp(area.grp)
  qwknet = get_qwknet(group)
  bbsid = ""
  bbsid = qwknet.bbsid if !qwknet.nil?
  if email then
    abs = email_absolute_message(mpointer,user.name)
  else
    abs = absolute_message(area.number,mpointer)
  end
  m_out = ""
  curmessage = fetch_msg(abs)
  m_out << m_menu(m_area,mpointer,dir,curmessage.subject.strip,curmessage.m_from.strip,total,email)
  if pointer.lastread < curmessage.absolute then
    pointer.lastread = curmessage.absolute
    update_pointer(pointer)
  end
  #      message = []

  #    if curmessage.network then
  #     message,kludge = qwk_kludge_search(curmessage.msg_text.strip)
  #   else
  message = curmessage.msg_text.strip
  #   end
  message.gsub!(13.chr,"<br/>")
  m_out << "<div class='fixed' style='background-color:black;color:white'>"
  m_out << "##{mpointer} <span style='color:#54fc54'>[</span><span style='color:#54fcfc'>#{curmessage.absolute}</span><span style='color:#54fc54'>]</span> <span style='color:#fc54fc'>"
  m_out << "#{curmessage.msg_date.strftime('%A the %d')}"
  m_out << "#{time_thingie(curmessage.msg_date)}"
  m_out << " of #{curmessage.msg_date.strftime('%B, %Y  %I:%M%p')}</span>"
  m_out <<  " <span style='color:#54fc54'> [QWK]</span>" if curmessage.network
  m_out << " [SMTP]" if curmessage.smtp
  m_out << "<span style='color:#54fc54'> [FIDONET]</span>" if curmessage.f_network
	m_out << "<span style='color:#54fc54'> [NNTP]</span>"  if curmessage.usenet_network
  m_out << "<span style='color: #fcfc54'> [EXPORTED]</span>" if curmessage.exported and !curmessage.f_network and !curmessage.network
  m_out << " [REPLY]" if curmessage.reply
  m_out << "<br>"
  m_out << "<table cellspacing=0>"
  m_out << "<tr><td> <span style='color:#54fcfc'>To:</span></td><td><span style='color:#54fc54'>#{curmessage.m_to}</span></td></tr>"
  m_out << "<tr><td><span style='color:#54fcfc'>From:</span></td><td><span style='color:#54fc54'>#{curmessage.m_from.strip}</span>"
  out = ""
  if curmessage.f_network then
    out = "UNKNOWN"
    if !curmessage.intl.nil? then
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
    out = bbsid
    out = curmessage.q_via if !curmessage.q_via.nil? and !curmessage.q_via.empty?
    m_out << " <span style='color:#54fc54'>(</span><span style='color:#54fcfc'>#{out}</span><span style='color:#54fc54'>)</span>"
  end
  m_out << "</td></tr>"
  m_out << "<tr><td><span style='color:#54fcfc'>Title: </span></td><td><span style='color:#54fc54'>#{curmessage.subject}</span></td></tr></table><br>"
  m_out << "<div id='msg'>"
  m_out << "#{(parse_webcolor(wordwrap(convert_to_ascii(message))))}"
  m_out << "</div></div>"
  m_out << "<BR>"
  return [curmessage.m_from.strip,curmessage.subject.strip,m_out]
end

def pntr(user,c_area)
  area = fetch_area(c_area)
  pointer = get_pointer(user,c_area)
  p_msg = m_total(area.number) - new_messages(area.number,pointer.lastread)
  p_msg = 1 if p_msg < 1
  return p_msg
end

def e_pntr(u)
  area = fetch_area(0)
  pointer = get_pointer(u,0)
  epointer = e_total(u.name) - new_email(pointer.lastread,u.name)
  epointer = 1 if epointer == 0
  return epointer
end

def e_hmsg(u)
  area = fetch_area(0)
  e_total(u.name)
end

def h_msg(c_area)
  area = fetch_area(c_area)
  h_msg = m_total(area.number)
  return h_msg
end

def validate_user(username)

  happy = username.rindex(/[,*@:\']/)

  if happy.nil? then
    if !user_exists(username) then
      puts username
      return OKAY
    else
      return EXISTS
    end
  else
    return INVALID
  end
end

post "/postsave" do   

  if !session[:name].nil? then

    name = session[:name]
    uid = get_uid(name)
    who_list_update(uid,"Writing a Message")

    m_area = params['m_area']
    m_area = m_area.to_i
    last = params["last"]
    last = last.to_i
    dir =params["dir"]
    dir = "+" if dir == ""
    msg_to = params["msg_to"]
    msg_subject=params["msg_subject"]
    msg_text=params['msg_text']
    e_uid = params['e_uid']
		nntpreferences = params['nntpreferences']
    qwk = false
    qwk = true if params['qwk'] == "t"
    fido = false
    fido = true if params['fido'] == "t"
    reply = false
    reply = true if params['reply'] == "t"
    pvt = false
    pvt = true if params['private'] == "t"
    abs = params['abs'].to_i
    intl = nil
    zone = nil
    net = nil
    node = nil

    post_out = ""
    area=fetch_area(m_area)
    area=fetch_area(0) if pvt
    user = fetch_user(get_uid(name))
    pointer = get_pointer(user,m_area)
    e_out,g_out = side_menu_gubbins


    if (pointer.access == "W") or (pointer.access == "C") or (pointer.access == "M") or (area.number == 0) or (user.level == 255) and (!area.delete) and (pointer.access !="N") then
      if !msg_to.nil? and !msg_to.empty? and pvt then
        if !reply then
          case determine_email_type(msg_to)
          when Q_NETMAIL
            qwk = true
            puts "!!!QWK NETMAIL ADDRESS DETECTED!!!"
          when F_NETMAIL
            fido = true
            puts "!!!FIDO NETMAIL ADDRESS DETECTED!!!"
            puts "qwk: #{qwk}"
          end # of case
        end
        if qwk then
          to,route = qwkmailadr(msg_to)
          if reply then
            reply_message = fetch_msg(abs)
            area = fetch_area(m_area)
            to = msg_to
          else
            area,path = qwk_route(route)
          end
          if !area.nil?
            group = fetch_group_grp(area.grp)
            qwknet = get_qwknet(group)
            bbsid=qwknet.bbsid
            area = find_qwk_area(QWKMAIL,qwknet.grp)
          end
          if !route.nil? and !route.empty? and !area.nil? then
            if route.upcase != bbsid then #kludge line for a user not on the QWK Hub
              out = ""
              out = "@#{reply_message.q_via}" if reply
              msg_text.insert(0,"#{msg_to}#{out}\r")   #get the kludge line, send email reply to the correct user
              msg_to = "NETMAIL" #tell the QWK hub it needs to forward the message.
            else
              msg_to = to #Otherwise, strip the QWK Hub name from the To: line
            end
          end
        else


          if fido then
            puts "reached fido!"
            to,zone,net,node,point = netmailadr(msg_to)
            puts "to: #{to}"
            puts "zone: #{zone}"
            puts "net: #{net}"
            puts "node: #{node}"
            puts "point: #{point}"
            area = fetch_area( find_fido_area(NETMAIL))
            intl = "#{zone}:#{net}/#{node} #{FIDOZONE}:#{FIDONET}/#{FIDONODE}"
          else
            if !e_uid.nil? and !e_uid.empty? then   #we've gotten a local email recp.
              msg_to = fetch_user(e_uid.to_i).name
            end
          end
        end
      end
      #more validations

      if !msg_subject.nil? then
        msg_subject = msg_subject[0..39] if msg_subject.length > 40
      end
      if !msg_to.nil?
        msg_to = msg_to[0..39] if msg_to.length > 40
      end
      msg_text = WordWrapper.wrap(msg_text,79)
      msg_text.gsub!(10.chr,"")
      msg_text = convert_to_utf8(msg_text)

      msg_date = Time.now
      #   absolute = add_msg(msg_to,name,msg_date,msg_subject,msg_text,false,false,false,nil,nil,nil,nil,false,area.number)
      if !area.nil?
        absolute = add_msg(msg_to,name,msg_date,msg_subject,msg_text,false,false,node,net,intl,nil,false,fido,nil,nil,
        nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,false,area.number,nil,nil,nil,nil,nntpreferences)
        system = fetch_system
        if !pvt
          system.posts_today += 1
        else
          system.emails_today += 1 
        end
        user.posted += 1
        update_user(user)
        update_system(system)
      end
      if area.nil? then
        post_out << "No route to this address. Check the routing <a href='/table'>table.</a> "
      else
        if qwk and pvt
          post_out << "QWK Netmail Sent. ##{absolute}<BR>"
        else
          if fido then
            post_out << "Fidonet Netmail Sent ##{absolute}<BR>"

          else
            if m_area == 0 then
              post_out << "Local Email Sent ##{absolute}<BR>"
            else
              post_out << "Posted Absolute Message ##{absolute}<BR>"
            end
          end
        end
      end
      out = "/message?m_area=#{m_area}&"
      out = "/email?" if m_area == 0
      post_out << ("<a href='#{out}last=#{last}&dir=#{dir}'>Return</a>&nbsp;&nbsp;")
    else
      post_out << 'You do not have access.'
    end
    e_out,g_out = side_menu_gubbins    #make the side menu database inserts on the sinatra side, like the manual says
    haml :post, :locals => {:email => e_out, :groups => g_out, :post => post_out}
  else
    haml :notlogged
  end
end

get '/post' do

  if !session[:name].nil? then

    name = session[:name]
    uid = get_uid(name)
    who_list_update(uid,"Post Message")
    post_out = ""
    m_area = params['m_area']
    m_area = m_area.to_i
    last =params["last"]
    last = last.to_i
    dir = params["dir"]
    dir = "+" if dir == ""
    to = params["to"]
    subject=params["subject"]
    pvt = false
    pvt = true if  params["pvt"]=="t"
    post_out << "Sending Private Message<br/>" if pvt
    user = fetch_user(get_uid(name))
    pointer = get_pointer(user,m_area)

    area=fetch_area(m_area)


    if (pointer.access == "W") or (pointer.access == "C") or (pointer.access == "M") or (area.number == 0) or (user.level == 255) and (!area.delete) and (pointer.access !="N") then
      reply = []
      puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
      puts "to: #{to}"


      post_out <<  "<table>"
      post_out << "<form name='main' method='post' action='/postsave'>"
      if !to.nil? then
        curmessage = fetch_msg(absolute_message(area.number,last))
        if !curmessage.nil?   # if curmessage is nil it means there was no message to load...
          puts "I'm here"
          reply =  convert_to_ascii(curmessage.msg_text)
          post_out <<  "<input name='reply' type='hidden' value='t'>"   #let the /postsave from know we are replying
          post_out <<  "<input name='abs' type='hidden' value='#{curmessage.absolute}'>" #let /postsave know the message id so it can get stuff from it
          post_out <<  "<input name='qwk' type='hidden' value='t'>"  if curmessage.network
          post_out <<  "<input name='fido' type='hidden' value='t'>" if curmessage.f_network
					post_out <<  "<input name='nntpreferences' type='hidden' value='#{curmessage.nntpreferences}'>" if curmessage.nntpreferences
        end
      end

      post_out << "<input name='dir' type='hidden'  value='#{dir}'>"
      post_out <<  "<input name='last' type='hidden' value='#{last}'>"
      post_out <<  "<input name='m_area' type='hidden' value='#{m_area}'>"
      post_out <<  "<input name='private' type='hidden' value='t'>" if pvt

      post_out <<  "<tr><td>From: </td> <td>#{name}</td></tr>"
      if pvt then
        if to.nil? or to.empty? then
          post_out << "<tr><td>To (local):</td>"
          post_out << "<td><select name='e_uid' size='1' style='width:200px;'>"
          fetch_user_list.each {|x|
            post_out << "<option value='#{x.number}'>#{x.name}</option>"
          }
          post_out << "</select>"
        else
          post_out <<  "<input name='msg_to' type='hidden' value='#{to}'>"
          post_out << "<tr><td>To:</td><td> #{to}"  #hmmm
        end
      else
      end
      if to.nil? or to.empty? then
        out = ""
        out = "(remote)" if pvt
        post_out << "<tr><td>To: #{out}</td>"  #hmmm
        post_out << "<td><input name='msg_to' type='text' id='msg_to'></td>"

      else
        post_out << "<td>To:</td><td> #{to}</td></tr>"
        post_out <<  "<input name='msg_to' type='hidden' value='#{to}'>"

      end
      post_out <<  "<tr><td>Subject:</td><td><input name='msg_subject' type='text' id='msg_subject' value='#{subject}'></td></tr>"
      post_out <<  "#{CRLF}"
      post_out <<  "<tr><td colspan=2><textarea style='font-size:12px' name='msg_text' cols='79' rows='25'  id='msg_text'>#{CRLF}"


      if !to.nil? and !reply.nil? and !reply.empty? then
        reply = reply.split(13.chr)
        post_out <<  ("--- #{to} wrote --- #{CRLF}")
        reply.each {|line| post_out << "&gt; #{line[0..75].strip}#{CRLF}"}
      end

      post_out << "</textarea></td>"
      post_out << "</tr>"
      post_out << "<tr>"
      post_out << "<td>&nbsp;</td>"
      post_out << "<td><input type='submit' name='Submit' value='Post'> </td>"
      post_out << "</tr>"
      post_out << "</form>"
      post_out << "</table>"
    else
      post_out << 'You do not have access.'
    end


    e_out,g_out = side_menu_gubbins    #make the side menu database inserts on the sinatra side, like the manual says

    haml :post, :locals => {:email => e_out, :groups => g_out, :post => post_out}
  else
    haml :notlogged
  end
end

post '/usersave' do

  username= params['username']
  new_password = params["new_password"]
  verify_password = params["verify_password"]
  email = params['email']
  location = params['location']

  frm_out = ""
  frm_out << "<form name='main' method='post' action='/newuser'>"
  frm_out << "<input name='username' type='hidden'  value='#{username}'>"
  frm_out <<  "<input name='email' type='hidden' value='#{email}'>"
  frm_out <<  "<input name='location' type='hidden' value='#{location}'>"
  frm_out << "<input name = 'Try Again' type = 'submit' value = 'Try Again'>"

  if (new_password.upcase.strip == verify_password.upcase.strip) and (new_password.length > 4) then
    happy = (/^(\S*)@(\S*)\.(\S*)/) =~ email
    if !happy.nil? then
      if location.length > 2 then
        user_to_make = validate_user(username)
        if user_to_make == OKAY then
          system = fetch_system
          system.newu_today += 1
          update_system(system)
          add_user(username,'000.000.000',new_password.upcase,location,email,24,80,true, true, DEFLEVEL, true)
          haml :usersuccess
        else
          case user_to_make
          when 1
            haml :userfailure, :locals => {:error => "Username Already Exists...", :frm_out => frm_out}
          when 2
            haml :userfailure, :locals => {:error => "User IDs must be between 3 and 25 characters, and may not contain...<br>the characters : * @ , ' ", :frm_out => frm_out}
          end
        end
      else
        haml :userfailure, :locals => {:error => "Invalid location.", :frm_out => frm_out}
      end
    else
      haml :userfailure, :locals => {:error => "Invalid E-mail address.", :frm_out => frm_out}
    end
  else
    if new_password.length < 5 then
      haml :userfailure, :locals => {:error =>"Passwords must be at least 5 characters.", :frm_out => frm_out}
    else
      haml :userfailure, :locals => {:error => "Passwords do not match.", :frm_out => frm_out}
    end
  end
end

get_or_post '/newuser' do

  username= params['username']
  email = params['email']
  location = params['location']

  n_out = ""
  n_out << "<table border = 0>"
  n_out << "<form action = '/usersave' method = 'post'">
  n_out << "<tr><td>Account Name<td><input name = 'username' value = '#{username}' id = 'username' type = 'text' maxlength = 50></td></tr>"
  n_out << "<tr><td>Password<td><input name = 'new_password' id = 'new_password' type = 'password' maxlength = 50></td></tr>"
  n_out <<  "<tr><td>Verify Password<td><input name = 'verify_password' id = 'verify_password' type = 'password' maxlength = 50></td></tr>"
  n_out <<  "<tr><td>Email<td><input name = 'email' id = 'email' value = '#{email}' type = 'text' maxlength = 50></td></tr>"
  n_out <<  "<tr><td>Location<td><input name = 'location' id = 'location' value = '#{location}' type = 'text' maxlength = 50></td></tr>"
  n_out << "<tr><td colspan = 2><input name = 'login' type = 'submit' value = 'create'></td></tr></table>"

  haml :newuser,  :locals => {:n_out => n_out}
end

get '/' do

  graphfile =  "welcome1.ans"
  plainfile =  "welcome1.txt"

  t_file = ROOT_PATH + TEXTPATH + "welcome1.ans"

  test = File.exists?(t_file) ? graphfile : plainfile

  haml :index, :locals => {:display_text => text_to_html(test,nil)}
end

get '/newusermsg' do

  graphfile =  "newuser.ans"
  plainfile =  "newuser.txt"

  t_file = ROOT_PATH + TEXTPATH + "newuser.ans"

  test = File.exists?(t_file) ? graphfile : plainfile

  haml :newusermsg, :locals => {:display_text => text_to_html(test,nil)}
end

get "/information" do

  if !session[:name].nil? then

    name = session[:name]
    uid = get_uid(name)
    who_list_update(uid,"Information")
    b_out = ""
    b_out << "<table cellspacing='5'>"
    for i in 1..(b_total)
      bulletin = fetch_bulletin(i)
      b_out << "<tr><td><a href='/bulletin?bull=#{i}'>#{bulletin.name}</a><br></tr>"
    end
    b_out << "</table>"
    e_out,g_out = side_menu_gubbins    #make the side menu database inserts on the sinatra side, like the manual says

    haml :information, :locals => {:email => e_out, :groups => g_out, :bulletin => b_out}
  else
    haml :notlogged
  end
end



get "/chat" do

  if !session[:name].nil? then

    name = session[:name]
    uid = get_uid(name)
    who_list_update(uid,"IRC Chat")
    user = fetch_user(get_uid(name))
    m_out = ""

    e_out,g_out = side_menu_gubbins    #make the side menu database inserts on the sinatra side, like the manual says

    if user.alias.nil? then
      m_out << "<p>You do not have an chat alias set. To set one click on <a href='/usrsettings'>User Settings</a>.</p>"
      haml :chat, :locals => {:email => e_out, :groups => g_out, :message => m_out}
    else
      m_out << '<p>Click chat to chat.  This will launch the our HTTP IRC client...</p>'
      m_out <<  "<form name='cgiirclogin' method='post' onsubmit='return openCgiIrc(this, 0)' action='chat/irc.cgi'>"
      m_out <<  "<input type='hidden' name='interface' value='nonjs'>"
      m_out <<  "<input type='hidden' name='Nickname' value='#{user.alias}'>"
      m_out <<  "<input type='hidden' name='Server' value='irc.larryniven.org'>"
      m_out <<  "<input type='hidden' name='Channel' value='#knownspace'>"
      m_out <<  "<input type='submit' value='Chat'>"
      m_out <<  "</form>"
    end


    haml :chat, :locals => {:email => e_out, :groups => g_out, :message => m_out}
  else
    haml :notlogged
  end
end



get "/page" do

  if !session[:name].nil? then

    name = session[:name]
    uid = get_uid(name)
    who_list_update(uid,"Page")

    user = fetch_user(uid)
    o_out = ""

    if  new_pages(user) then
      pages = get_all_pages(user)
      o_out <<  '<table class="green_table" width="100%">'
      o_out << "<form name='delete' method='post' action='/pagedelete'>"
      o_out << '<th>Del<th>From</th><th>Message</th>'
      pages.each{|x| o_out << "<tr><td><input type='checkbox' name='del_box[]' value = '#{x.id}'></td><td><a href='/pagesend?uid=#{x.from}'>#{fetch_user(x.from).name}</a></td><td>#{x.message}</td></tr>"}

      o_out << '</table>'
      o_out << 'Click on an existing page to reply, or <a href="/pagesend">page</a> another user.<br>'
      o_out  <<  "To delete a message(s) tick and <input type='submit' value='Delete'>"
    end
    e_out,g_out = side_menu_gubbins    #make the side menu database inserts on the sinatra side, like the manual says

    haml :page, :locals => {:email => e_out, :groups => g_out, :output => o_out}
  else
    haml :notlogged
  end
end

post "/pagedelete" do

  if !session[:name].nil? then

    del_box = params["del_box"]
    name = session[:name]
    uid = get_uid(name)
    user = fetch_user(uid)
    if del_box.nil? then
      redirect '/page'
    else
      del_box.each{|x| delete_page(x)}
      redirect '/page'
    end
  else
    haml :notlogged
  end
end

get_or_post "/delete" do

  if !session[:name].nil? then

    abs = params[:abs]
    area = params[:area]
    name = session[:name]
    doit = params[:doit]
    uid = get_uid(name)
    user = fetch_user(uid)
    e_out,g_out = side_menu_gubbins    #make the side menu database inserts on the sinatra side, like the manual says

    if !abs.nil? then
      message = fetch_msg(abs)
      abs = nil if message.nil?
    end

    out = "/message?m_area=#{area}"
    out = "/email" if area == 0

    if !abs.nil? then

      if (user.level == 255) or (message.m_from.downcase == user.name.downcase) or (message.number == 0 and m_to.downcase == user.name.downcase) then
        if doit == "Y" then
          delete_msg(abs)
          o_out = "Message (#{abs}) Deleted. <a href='#{out}'>Back</a>"
          haml :delete, :locals => {:email => e_out, :groups => g_out, :output => o_out}
        else
          err_out = "Delete Message, are you sure? <a href='/delete?abs=#{abs}&area=#{area}&doit=Y'>Yes</a>."
          haml :deleteerror, :locals => {:email => e_out, :groups => g_out, :err =>err_out}
        end
      else
        err_out = "You may only delete your own messages.  <a href='#{out}'>Back</a>"
        haml :deleteerror, :locals => {:email => e_out, :groups => g_out, :err =>err_out}
      end
    else
      err_out = "Message Not Found.  <a href='#{out}'>Back</a>"
      haml :deleteerror, :locals => {:email => e_out, :groups => g_out, :err =>err_out}
    end
  else
    haml :notlogged
  end
end


get "/pagesend" do

  if !session[:name].nil? then

    p_uid = params[:uid]
    name = session[:name]
    uid = get_uid(name)
    who_list_update(uid,"Page")
    user = fetch_user(uid)
    if !p_uid.nil? then
      p_user = fetch_user(p_uid)
    end
    o_out = ""
    o_out = "<table>"
    o_out << "<form name='main' method='post' action='/pagesave'>"
    # o_out <<  "<input name='m_area' type='hidden' value= >"
    if p_uid.nil? then
      o_out << "<tr><td>To:</td>"
      o_out << "<td><select name='p_uid' size='1' style='width:200px;'>"
      fetch_user_list.each {|x|
        o_out << "<option value='#{x.number}'>#{x.name}</option>"
      }
      o_out << "</select>"
    else
      o_out << "<tr><td>To: #{p_user.name}"
      o_out <<  "<input name='p_uid' type='hidden' value='#{p_uid}' >"
    end
    o_out << "</td></tr>"
    o_out <<  "<tr><td colspan=2><textarea style='font-size:12px' name='msg_text' cols='50' rows='5'  id='msg_text'>"
    o_out << "</textarea></td>"
    o_out << "</tr>"
    o_out << "<tr>"
    o_out << "<td>&nbsp;</td>"
    o_out << "<td><input type='submit' name='Submit' value='Send'>"

    o_out << "&nbsp;&nbsp;Pages are limited to 240 characters."
    o_out << "</td></tr></form></table>"
    e_out,g_out = side_menu_gubbins    #make the side menu database inserts on the sinatra side, like the manual says

    haml :page, :locals => {:email => e_out, :groups => g_out, :output => o_out}
  else
    haml :notlogged
  end
end

post "/pagesave" do

  if !session[:name].nil? then
    p_uid = params["p_uid"]
    msg_text = params["msg_text"]
    name = session[:name]
    p_user = fetch_user(p_uid.to_i)

    uid = get_uid(name)
    user = fetch_user(uid)

    e_out,g_out = side_menu_gubbins
    who_list_update(uid,"Page")

    if p_user.nil? then
      err_out = "Invalid User ID! #{p_uid}"
      haml :pageerror, :locals => {:email => e_out, :groups => g_out, :err => err_out}
    else
      if msg_text.length > 240 then
        err_out = "Page Too Long!  Pages are limited to 240 Characters."
        haml :pageerror, :locals => {:email => e_out, :groups => g_out, :err => err_out}
      else
        err_out = "Page Sent."
        add_page(uid.to_i,p_user.name,msg_text,false)
        haml :pagesucc, :locals => {:email => e_out, :groups => g_out}
      end
    end

  else
    haml :notlogged
  end
end

post "/passwordsave" do

  if !session[:name].nil? then

    name = session[:name]

    old_password = params['old_password']
    new_password = params["new_password"]
    verify_password = params["verify_password"]

    uid = get_uid(name)
    user = fetch_user(uid)

    e_out,g_out = side_menu_gubbins
    who_list_update(uid,"Saving User Settings")

    if old_password.upcase.strip != user.password.strip then
      err_out = "You must enter your correct current password!"
      haml :passerror, :locals => {:email => e_out, :groups => g_out, :err => err_out}
    else
      if new_password.upcase.strip == verify_password.upcase.strip then
        user.password = new_password.upcase.strip
        update_user(user,get_uid(user.name))
        haml :passsucc, :locals => {:email => e_out, :groups => g_out}
      else
        err_out = "Passwords do not match.  Try again!"
        haml :passerror, :locals => {:email => e_out, :groups => g_out, :err =>err_out}
      end
    end

  else
    haml :notlogged
  end
end


post "/chatsave" do

  if !session[:name].nil? then

    name = session[:name]
    new_alias=params["chat_alias"]
    uid = get_uid(name)
    user = fetch_user(uid)

    e_out,g_out = side_menu_gubbins
    who_list_update(uid,"Saving Chat Alias")
    newalias = new_alias.strip.to_s.slice(0..14)
    if newalias == user.alias then
      err_out = "That is already your alias."
      haml :aliaserror, :locals => {:email => e_out, :groups => g_out, :err => err_out}
    else
      if !alias_exists(newalias) then
        user.alias = newalias
        update_user(user)
        haml :aliassucc, :locals => {:email => e_out, :groups => g_out}
      else
        err_out << "That alias is in use by another user."
        haml :aliaserror, :locals => {:email => e_out, :groups => g_out, :err => err_out}
      end
    end

  else
    haml :notlogged
  end
end


get "/usrsettings" do

  if !session[:name].nil? then

    name = session[:name]
    uid = get_uid(name)
    who_list_update(uid,"User Settings")

    user = fetch_user(get_uid(name))
    pass_out = ""
    pass_out << '<table border="0">'
    pass_out <<  '<td>'
    pass_out <<  '<FORM ACTION="/passwordsave" METHOD="post"> '
    pass_out <<  ' <TR><TD>Old Password</td><td>'
    pass_out <<   '<input name="old_password" type="password" id="old_password">'
    pass_out <<   '</td></tr>'
    pass_out <<   ' <TR><TD>New Password</td><td>'
    pass_out <<   '<input name="new_password" type="password" id="new_password">'
    pass_out <<   '</td></tr>'
    pass_out <<   ' <TR><TD>Verify Password</td><td>'
    pass_out <<   '<input name="verify_password" type="password" id="verify_password">'
    pass_out <<   '</td></tr>'
    pass_out <<   '<TR><TD>'
    pass_out <<   '<input type="submit" name="Submit" value="Save">'
    pass_out <<   '</form>'
    pass_out <<   '</table>'

    chat_out = ""

    chat_out << '<table border="0">'
    chat_out <<'<td>'
    chat_out << '<FORM ACTION="/chatsave" METHOD="post"> '
    chat_out << ' <TR><TD>Chat Alias</td><td>'
    chat_out << "<input name='chat_alias' value='#{user.alias}' id='chat_alias'>"
    chat_out << '</td></tr>'
    chat_out << '<TR><TD>'
    chat_out << '<input type="submit" name="Submit" value="Save">'
    chat_out << '</form>'
    chat_out << '</table>'
    e_out,g_out = side_menu_gubbins    #make the side menu database inserts on the sinatra side, like the manual says

    haml :usrsettings, :locals => {:email => e_out, :groups => g_out, :password => pass_out, :chat => chat_out }
  else
    haml :notlogged
  end
end

get "/showuser" do

  if !session[:name].nil? then

    name = session[:name]
    uid = get_uid(name)
    who_list_update(uid,"User Details")

    o_uid=params['uid'].to_i
    o_user = fetch_user(o_uid)


    o_out = ""
    o_out <<  '<table class="green_table">'
    o_out <<  "<tr><td>Email:</td><td>#{o_user.address}</td></tr>"
    o_out <<  "<tr><td>Location:</td><td>#{o_user.citystate}</td></tr>"
    o_out <<  "<tr><td>Last on:</td><td>#{o_user.laston}</td></tr>"
    o_out <<  "<tr><td>Access level:</td><td>#{o_user.level}</td></tr>"
    o_out <<  "<tr><td>Chat alias:</td><td>#{o_user.alias}</td></tr>"
    o_out << '</table>'
    e_out,g_out = side_menu_gubbins    #make the side menu database inserts on the sinatra side, like the manual says

    haml :showuser, :locals => {:email => e_out, :groups => g_out, :output => o_out, :username => o_user.name }
  else
    haml :notlogged
  end
end

get "/users" do

  if !session[:name].nil? then

    name = session[:name]
    uid = get_uid(name)
    who_list_update(uid,"User List")
    u_out = ""
    u_out << "<table class = 'green_table'>"
    u_out << "<th>User ID</th><th>Location</th>"
    fetch_user_list.each {|x|
      u_out << "<tr>"
      for i in 0..1 do
        if i == 0 then
          u_out << "<td><a href='/showuser?uid=#{x.number}'>#{x.name}</a>"
        else
          u_out <<  "<td>#{x.citystate} </td>"
        end

      end
    u_out << "</tr>"}
    u_out << "</table>"
    e_out,g_out = side_menu_gubbins    #make the side menu database inserts on the sinatra side, like the manual says

    haml :userlist, :locals => {:email => e_out, :groups => g_out, :users => u_out}
  else
    haml :notlogged
  end
end

get "/who" do

  if !session[:name].nil? then

    name = session[:name]
    uid = get_uid(name)
    who_list_update(uid,"Who is Online")
    w_out = ""
    w_out << "<h3>Web Users:</h3>"
    w_out <<  "<table class='green_table'>"
    w_out <<  "<th>User ID</th><th>Location</th><th>Last Activity</th><th>Where</th>"
    fetch_who_list.each {|x|
      w_out <<  "<tr><td><a href='/showuser?uid=#{x.number}'>#{x.user.name}</a>"
      time = x.lastactivity.strftime('%Y-%m-%d %I:%M%p')
      w_out <<  "<td>#{x.user.citystate} </td><td>#{time} </td><td>#{x.place}</td></tr>"
    }
    w_out <<  "</table>"
    w_out <<   "<table class='green_table'>"
    w_out <<  "<h3>Telnet Users:</h3>"
    w_out <<  "<th>Node</th><th>User ID</th><th>Location</th><th>Where</th>"
    fetch_who_t_list.each {|x|
      w_out <<   "<tr><td>#{x.node}"
      w_out <<   "<td>#{x.name} </td><td>#{x.location} </td><td>#{x.where}</td></tr>"
    }
    w_out <<   "</table>"
    e_out,g_out = side_menu_gubbins    #make the side menu database inserts on the sinatra side, like the manual says

    haml :who, :locals => {:email => e_out, :groups => g_out, :who => w_out}
  else
    haml :notlogged
  end
end

get "/last" do

  if !session[:name].nil? then

    wall_cull
    name = session[:name]
    uid = get_uid(name)
    who_list_update(uid,"Last Callers")
    l_out = ""
    l_out << "<table class='green_table'>"
    l_out <<  "<th>User ID</tn><th>Date</th><th>Connection</th>"

    fetch_wall.each {|x|
      t= Time.parse(x.timeposted.to_s).strftime("%m/%d/%y %I:%M%p")
    l_out << "<tr><td>#{x.user.name}</td><td>#{t}</td><td>#{x.l_type}</td></tr>"}
    l_out << "</table>"
    e_out,g_out = side_menu_gubbins    #make the side menu database inserts on the sinatra side, like the manual says

    haml :last, :locals => {:email => e_out, :groups => g_out, :last => l_out}
  else
    haml :notlogged
  end
end

get "/log" do

  if !session[:name].nil? then

    name = session[:name]
    uid = get_uid(name)
    who_list_update(uid,"System Log")
    dir = "f"
    last = 0

    D_MAX = 25

    dir = params['dir'] if !params['dir'].nil?
    last = params['last'].to_i if !params['last'].nil?

    if dir == "f" then
      stop = last + D_MAX
      stop = log_size-1 if stop >= log_size-1
    end

    if dir =="b" then
      stop = last -  D_MAX
      last = last - (D_MAX * 2)
      stop = 0 if stop < 0
    end

    l_out = ""

    if stop - D_MAX > 0 then
      l_out << "<a href='/log?last=#{stop}&dir=b'>Prev</a>&nbsp;&nbsp;&nbsp;"
    end

    if stop < log_size-1 then
      l_out << "<a href='/log?last=#{stop}&dir=f'>Next</a>"
    end

    l_out << "<table class='green_table'><th>Date</th><th>Sub-system</th><th>Entry</th>"
    arr = fetch_log(0)
    for i in last..stop
      x = arr[i]
      t= Time.parse(x.ent_date.to_s).strftime("%m/%d/%y %I:%M%p")

      l_out << "<tr><td>#{t} </td><td>#{x.subsys.name} </td><td>#{x.message}</td></tr>"
    end
    l_out << "</table>"


    if stop-D_MAX > 0 then
      l_out << "<a href='/log?last=#{stop}&dir=b'>Prev</a>&nbsp;&nbsp;&nbsp;"
    end

    if stop < log_size-1 then
      l_out <<  "<a href='/log?last=#{stop}&dir=f'>Next</a>"
    end

    e_out,g_out = side_menu_gubbins    #make the side menu database inserts on the sinatra side, like the manual says

    haml :log, :locals => {:email => e_out, :groups => g_out, :log => l_out}
  else
    haml :notlogged
  end
end

get '/about' do
  haml :about, :locals =>{:title => TITLE}
end

post '/clogon' do

  happy =""
  name = params["acc_name"]
  passwd = params["password"].upcase
  if user_exists(name) and  check_password(name,passwd) then
    session[:name] = name
    uid = get_uid(name)
    who_list_add(uid) #add user to the list of web users online
    add_wall(uid,"","Web")
    system = fetch_system
    system.total_logons += 1
    system.logons_today += 1
    update_system(system)
    redirect "/welcome"
  else

    haml :failure
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
    name = session[:name]
    uid = get_uid(name)
    user = fetch_user(get_uid(name))
    haml :welcome,  :locals => {:display_text => text_to_html(test,user)}
  else
    haml :notlogged
  end
end

get '/bulletin' do


  if !session[:name].nil? then

    name = session[:name]
    uid = get_uid(name)
    user = fetch_user(get_uid(name))
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

    haml :bulletin,  :locals => {:email => e_out, :groups => g_out,:display_text => text_to_html(test,user)}
  else
    haml :notlogged
  end
end

get "/areas" do

  if !session[:name].nil? then

    grp = params["m_grp"]
    name = session[:name]
    uid = get_uid(name)
    who_list_update(uid,"Area List")
    a_out,n_out = area_list_gubbins(grp)
    e_out,g_out = side_menu_gubbins    #make the side menu database inserts on the sinatra side, like the manual says

    haml :areas, :locals => {:email => e_out, :groups => g_out, :areas => a_out, :g_name => n_out}
  else
    haml :notlogged
  end

end

get "/email" do

  if !session[:name].nil? then
    e_uid = params[:uid]
    m_area = 0
    last = params["last"]
    last = last.to_i
    dir = params["dir"]
    name = session[:name]
    uid = get_uid(name)
    who_list_update(uid,"Reading Email")
    user = fetch_user(get_uid(name))
    scanforaccess(user)
    area=fetch_area(m_area)
    pointer = get_pointer(user,m_area)
    m_out = ""

    if (pointer.access != "N") or (user.level == 255) and (!area.delete) then
      if last == 0 then
        pointer = e_pntr(user)
        if e_hmsg(user) > 0 then

          from,subject,tempstr = w_display_message(pointer,user,m_area,true,dir,e_hmsg(user))
          m_out << tempstr
          m_out << "<BR>"
          m_out << m_menu(m_area,pointer,dir,subject,from,e_hmsg(user),true)
        else m_out << "No Messages.  Send an <a href='/post?m_area=0&pvt=t'>Email." end


      else
        if e_hmsg(user) > 0 then
          if dir == "j" then
            if last <= e_hmsg(user) and last > 0 and e_hmsg(user) > 0 then
              from,subject,tempstr = w_display_message(last,user,m_area,true,dir,e_hmsg(user))
              m_out << tempstr
              m_out << "<BR>"
              m_out << m_menu(m_area,pointer,dir,subject,from,e_hmsg(user),true)
            else
              m_out << "Out of Range."
            end
          else
            if dir == "f" then
              if last < e_hmsg(user) then
                pointer = last+1

                from,subject,tempstr = w_display_message(pointer,user,m_area,true,dir,e_hmsg(user))
                m_out << tempstr
                m_out << "<BR>"
                m_out << m_menu(m_area,pointer,dir,subject,from,e_hmsg(user),true)
              else
                m_out << "Highest Message."
                pointer = e_hmsg(user)
                m_out << "<BR>"
                m_out << m_menu(m_area,pointer,dir,subject,from,e_hmsg(user),true)
              end
            else
              if last > 1 then
                pointer = last-1

                from,subject,tempstr = w_display_message(pointer,user,m_area,true,dir,e_hmsg(user))
                m_out << tempstr
              else
                m_out << "Lowest Message"
                pointer = 1
                m_out << "<BR>"
                m_out << m_menu(m_area,pointer,dir,subject,from,e_hmsg(user),true)
              end
            end
          end

        else
          m_out << "No Email."
        end

      end

    end




    e_out,g_out = side_menu_gubbins    #make the side menu database inserts on the sinatra side, like the manual says

    haml :message, :locals => {:email => e_out, :groups => g_out, :message => m_out}
  else
    haml :notlogged
  end

end


get_or_post "/message" do

  if !session[:name].nil? then

    grp = params["m_grp"]
    m_area = params['m_area']
    m_area = m_area.to_i
    last = params["last"]
    last = last.to_i
    dir = params["dir"]
    name = session[:name]
    uid = get_uid(name)
    who_list_update(uid,"Reading Messages")
    user = fetch_user(get_uid(name))
    scanforaccess(user)
    area=fetch_area(m_area)
    pointer = get_pointer(user,m_area)
    m_out = ""

    if (pointer.access != "I") or (user.level == 255) and (!area.delete) then
      if last == 0 then
        pointer = pntr(user,m_area)

        if h_msg(m_area) > 0 then

          from,subject,tempstr = w_display_message(pointer,user,m_area,false,dir,h_msg(m_area))
          m_out << tempstr
        else m_out << "No messages." end


      else
        if m_total(area.number) > 0 then
          if dir == "j" then
            if last <= h_msg(m_area) and last > 0 and m_total(area.number) > 0 then
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
    m_out << m_menu(m_area, pntr(user,m_area) ,dir,subject,from,h_msg(m_area),false)

    e_out,g_out = side_menu_gubbins    #make the side menu database inserts on the sinatra side, like the manual says

    haml :message, :locals => {:email => e_out, :groups => g_out, :message => m_out}
  else
    haml :notlogged
  end

end

get "/main" do

  if !session[:name].nil? then

    name = session[:name]
    uid = get_uid(name)
    who_list_update(uid,"Main Menu")
    e_out,g_out = side_menu_gubbins    #make the side menu database inserts on the sinatra side, like the manual says

    haml :main, :locals => {:email => e_out, :groups => g_out, :name => name}
  else
    haml :notlogged
  end
end
