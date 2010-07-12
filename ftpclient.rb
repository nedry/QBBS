require 'db/db_log'
require 'consts'

class FtpClient
  attr_reader :address, :account, :passwd

  def initialize(address, account, passwd)
    @address = address
    @account = account
    @passwd = passwd
  end

  def connect
    begin
      ftp = Net::FTP.new(@address)
      ftp.debug_mode = true
      ftp.passive = true
      ftp.login(@account, @passwd)
      yield ftp
    ensure
      ftp.close
    end
  end

  def qwk_packet_down
    begin
      connect do |ftp|
        ftp.getbinaryfile(QWKPACKETDOWN,QWKPACKET,1024)
      end
      add_log_entry(4,Time.now,"QWK Packet Download Successfull")
      puts "-QWK: Download Successful"
    rescue
      puts "-QWK: FTP Download Failure.  No new msgs?"
      add_log_entry(4,Time.now,"QWK Download Failure. No new msgs?")
    end
  end

  def rep_packet_up
    begin
      connect do |ftp|
        ftp.putbinaryfile(REPPACKET, REPPACKETUP, 1024)
      end
      add_log_entry(3, Time.now, "FTP QWK upload success.")
      puts "-REP: FTP QWK Upload Successful"
      return true
    rescue
      puts "-REP: FTP REP Upload Failure"
      add_log_entry(8,Time.now," FTP REP Upload Failure.")
      return false
    end
  end
end
