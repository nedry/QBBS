##############################################
#											
#   nntp.rb --NNTP server for QBBS.		                                
#   (C) Copyright 2012, Fly-By-Night Software (Ruby Version)                        
#  
#   This is mainly to connect QBBS and MajorBBS.  
##############################################

#!/usr/bin/ruby
$LOAD_PATH << "."

require 'consts.rb'
require 'dm-core'
require 'dm-validations'
require 'dm-aggregates'
require "db/db_area"
require "db/db_bulletins"
require "db/db_message"
require "db/db_doors"
require "db/db_bbs"
require "db/db_system"
require "db/db_themes"
require "db/db_who"
require "db/db_who_telnet.rb"
require "db/db_wall.rb"
require "db/db_log.rb"
require "db/db_groups"
require "db/db_user"
require "db/db_screen"
require "message.rb"
require "iconv"
require "socket"


NNTP_PORT = "119"
# -*- ruby -*-
require 'socket'
require 'thread'
require 'time'

NNTPLISTENPORT =1199

class NNTPSession
	
	def initialize(socket)
		@socket = socket
	end

def run
	puts "starting"
end

end
class NNTPServerSocket
  def initialize
    @serverSocket = TCPServer.open(NNTPLISTENPORT)
  end

  def run
    
    #add_log_entry(L_MESSAGE,Time.now,"#{VER} NNTP Server Starting.")
    if DEBUG then
      Thread.abort_on_exception = true 
      #add_log_entry(L_MESSAGE,Time.now,"NNTP Server running in Debug mode.")
    end

    while true
      puts "-NNTSRV: Starting Server Accept Thread";
      $stdout.flush
      if socket = @serverSocket.accept then
        Thread.new {
          puts "-NNTP: New Incoming Connection"
          NNTPSession.new(socket).run
        }
      end
    end
  end
end #class ServerSocket

nntpsock = NNTPServerSocket.new

puts "\n-#{VER} NNTP Server\n"; $stdout.flush
puts
puts "-Starting Up."; $stdout.flush
puts
nntpsock.run




DataMapper::Logger.new('log/db', :debug)
DataMapper.setup(:default, "postgres://#{DATAIP}/#{DATABASE}")
DataMapper.finalize
