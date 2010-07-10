require 'top.rb'

#  ------------------ MAIN ------------------

#puts "hello world"
$stdout.flush

DataMapper::Logger.new('log/db', :debug)
DataMapper.setup(:default, "postgres://#{DATAIP}/#{DATABASE}")

who = Who_old.new
message = []
irc_who =Irc_who.new

ssock = ServerSocket.new(irc_who, who, message)

puts "-Starting Up."; $stdout.flush
ssock.run
