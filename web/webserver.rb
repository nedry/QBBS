require 'rubygems'
require 'sinatra'
require 'haml'
require "pg_ext"

require "ansi.rb"
require "../db.rb"
require "../db_user.rb"
require "../db_who.rb"
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

def w_open_database
 
 begin
  @db = PGconn.connect(DATAIP,5432,"","",DATABASE,DB_UID,DB_PASSWD)
 rescue
  print "Fatal Error: Database Connection Failed.  Halted."
 end
end

def close_database
  @db.close
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
     redirect "/welcome"
   else
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