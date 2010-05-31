##############################################
#											
#   smtp.rb --SMTP message routines for QBBS.		                                
#   (C) Copyright 2004, Fly-By-Night Software (Ruby Version)                        
#                                                                                                            
############################################## 

require 'net/smtp'
require "pg_ext"
require 'rmail'
require "consts.rb"
require "db/db_message.rb"
require "db/db_area.rb"
require "db/db_class.rb"
require "db.rb"

def part_type(part)
  type = nil
  msg_array = part.to_s.split("\n")

  #msg_array.each {|x| x.chomp!}
  match = (/^(Content-Type:)\s(.+)/) =~ msg_array[0]
  if match then
    type = $2
    type.chop! if type[type.length - 1] == 59 # ; character
  end
  return type
end

def smtp_addr_to_qbbs(address)
  local = nil
  match = (/(.+)@(.+)\.(.+)/) =~ address
  if match then
    local = $1.gsub("."," ").upcase
  end
  return local
end

def delete_mail
  happy = system("rm #{TEMPSMTPDIR}")
end

def move_mail

  if File.exists?(MAILBOXDIR) then
    happy = system("mv -f #{MAILBOXDIR} #{TEMPSMTPDIR}")
    if happy then return SMTP_SUCCESS else return SMTP_MOVE_ERROR end
  else 
    return NO_SMTP_TO_COPY
  end
end

def which_part(part)

  return result 
end

def find_a_part(message)
  result = []
  message.each_part {|x| result << part_type(x)}
  result.each {|x| puts "-->#{x}"}
  return result
end

def s_local(user)
  if !user_exists(user) then 
    return false
  else 
    return true
  end
end

def smtp_to_msgtxt(intext)
  msg = intext.to_s
  msg_array = msg.to_s.split("\n")
  match = (/^(Content-Type:)\s(.+)/) =~ msg_array[0]
  msg_array[0] = nil if match
  match = (/(charset=)(.+)/) =~ msg_array[1]
  msg_array[1] = nil if match
  match = (/^(Content-Transfer-Encoding:)\s(.+)/) =~ msg_array[2]
  msg_array[2] = nil if match
  msg_array.compact!
  result = msg_array.join(DLIM)
  return result
end

def bounce_message(to,user)
  msgstr = "\nThe user: #{user} does not exist on this system.\nI'm sorry it didn't work out.\n"
  msg = [ "From: postmaster <#{POSTMASTER}>\n","To: #{to}\n","Subject: Delivery Failure\n", "\n", "#{msgstr}" ]
  Net::SMTP.start(SMTPSERVER, 25) do |smtp|
    smtp.send_message(msg, POSTMASTER, to)
    #smtp.send_message msg, "postmaster <#{POSTMASTER}>", to
  end

end
def read_mailbox

  area = fetch_area(0)

  File.open(TEMPSMTPDIR) { |file|
    RMail::Mailbox::MBoxReader.new(file).each_message { |input|
      message = RMail::Parser.read(input)
      address = message.header.to.first.address
      from = message.header.from.first.address.to_s
      subject = message.header.subject.to_s
      msg_date = message.header.date.to_s
      puts
      puts "FROM: #{from}"
      puts "TO:   #{address}"
      puts "SUBJ: #{subject}"
      puts "MT:   #{message.header.media_type}"
      puts "ST:   #{message.header.subtype}"
      puts
      l_address = smtp_addr_to_qbbs(address)
      puts "l_address: #{l_address}"
      msgtext = "***No Message***"
      if s_local(l_address) then
        if !message.multipart? then
          puts "-SMTP: Single Part Message"
          msgtext = smtp_to_msgtxt(message.body.to_s)
        else
          puts "-SMTP: Multiple Part Message"
          result = find_a_part(message)

          if result.index("text/plain") then 
            msgtext = smtp_to_msgtxt(message.part(result.index("text/plain")))
          else
            if result.index("text/html") then
              msgtext = smtp_to_msgtxt(message.part(result.index("test/html")))
            else
              if result.index("multipart/alternative") then
                result2 = find_a_part(message.part(result.index("multipart/alternative")))
                if result2.index("text/plain") then
                  msgtext = smtp_to_msgtxt(message.part(result.index("multipart/alternative")).part(result2.index("text/plain")))
                else
                  if result2.index("text/html") then
                    msgtext = smtp_to_msgtxt(message.part(result.index("multipart/alternative")).part(result2.index("test/html")))
                  end
                end
              end
            end
          end

        end
        puts msgtext
        add_msg(area.tbl, l_address,from,msg_date,subject,msgtext,false,false,false,nil,nil,nil,nil,true)
      else
        puts "-SMTP: Local user not found.  Bouncing Message."
        bounce_message(from,address)
      end

    }
  }
end

def do_smtp
  puts "-SMTP: Starting a email import"
  #open_database
  continue = move_mail
  if continue == SMTP_SUCCESS then
    read_mailbox
    delete_mail
  else
    puts "-SMTP: No mail..."
  end
  #@db.close
end
