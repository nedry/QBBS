require 'rubygems'
require 'sinatra'

get '/' do
 "<h1>Hello world  #{Time.now}</h1>"
end

get '/about' do
	"I'm running on Version " + Sinatra::VERSION
end