require 'top.rb'

#  ------------------ MAIN ------------------

#puts "hello world"
$stdout.flush

DataMapper::Logger.new('log/db', :debug)
DataMapper.setup(:default, "postgres://#{DATAIP}/#{DATABASE}")
#Encoding.default_internal = 'utf-8'
#Encoding.default_external = 'utf-8'
who = Who_old.new
message = []
log = Log.new
irc_who =Irc_who.new

ssock = ServerSocket.new(irc_who, who, message, log)

puts "-Starting Up."; $stdout.flush
ssock.run
