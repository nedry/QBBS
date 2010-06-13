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
require "../db/db_who.rb"
require "../db/db_groups.rb"
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
 open_database 
 groups = fetch_groups
 name = session[:name]
 uid = get_uid(name)

    if w_scanformail(uid) then
    e_out = '<a href="/email">Email (New!)</a><br>'
   else
     e_out = '<a href="/email">Email</a><br>'
   end
   
   g_out = ""
      groups.each {|group| line = "<li><a href='areas.rbx?m_grp=#{group.number}'>#{group.groupname}</a></li>"
              g_out << (line)}
   close_database
 return [e_out,g_out]
end

get '/' do
	
graphfile =  "welcome1.ans"
 plainfile =  "welcome1.txt"

 t_file = ROOT_PATH + TEXTPATH + "welcome1.ans"

 test = File.exists?(t_file) ? graphfile : plainfile
	
  haml :index, :locals => {:display_text => text_to_html(test)}
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
     session[:uid] =  get_uid(name) 
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
  session[:uid] = nil
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

get "/main" do

if !session[:name].nil? then
 
 e_out,g_out = side_menu_gubbins
		
  haml :main, :locals => {:email => e_out, :groups => g_out}
 else 
   haml :notlogged
 end
end