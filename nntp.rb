##############################################
#											
#   nntp.rb --NNTP connector for QBBS.		                                
#   (C) Copyright 2012, Fly-By-Night Software (Ruby Version)                        
#                                                                                                            
##############################################

require "socket"

NNTP_HOST = "news-europe.giganews.com"
NNTP_PORT = "119"


def open_nntp(host, port)

  begin
    @sock = TCPSocket.open(host, port)
    puts "Connected!"
  rescue
    puts "-Error: cannot resolve NNTP server."
  end
 end

def nntp_send(message)
  if message
    @sock.send("#{message}\r\n", 0)
  end
end

def nntp_recv  # Get the next line from the socket.
      
  reply = @sock.gets

  if reply
    reply.strip!
  end

  return reply

end

    # Shuts down the receive (how == 0), or send (how == 1), or both
    # (how == 2), parts of this socket.
    def nntp_shutdown(how=2)
      @sock.shutdown(how)
    end

open_nntp(NNTP_HOST, NNTP_PORT)

