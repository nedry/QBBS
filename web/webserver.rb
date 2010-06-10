require 'rubygems'
require 'sinatra'
require 'haml'

require 'functions.rb'

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


get '/' do
  haml :layout
 #"<h1>Hello world  #{Time.now}</h1>"
end

get '/about' do
	"I'm running on Version " + Sinatra::VERSION
end