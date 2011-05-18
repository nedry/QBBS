
$LOAD_PATH << "."
require 'top.rb'
require 'consts.rb'

#  ------------------ MAIN ------------------

$stdout.flush

DataMapper::Logger.new('log/db', :debug)
DataMapper.setup(:default, "postgres://#{DATAIP}/#{DATABASE}")

who = Who_old.new
message = []
irc_who =Irc_who.new

ssock = ServerSocket.new(irc_who, who, message)

puts "\n-#{VER} Server\n"; $stdout.flush
puts
puts "-Starting Up."; $stdout.flush
puts
ssock.run
