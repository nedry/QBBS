require 'rubygems'
require 'sinatra'
require 'haml'
require "pg_ext"

require "../db.rb"
require "../db_user.rb"
require "../db_who.rb"
require "../consts.rb"


 enable :sessions

TEXT_ROOT = "/home/mark/qbbs/text/"
TITLE = "QUARKseven Web Interface (v.01)"

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
 		  line.gsub!(" ","&nbsp;")
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
	
  haml :index, :locals => {:display_text => text_to_html("welcome1.txt")}
end

get '/about' do
  haml :about, :locals =>{:title => TITLE}
end

post '/clogon' do
  open_database
  name = params["acc_name"]
  passwd = params["password"]
  if user_exists(name) then 
   if check_password(name,passwd) then
     haml :success 
   else
     haml :failure
  end
end
end
