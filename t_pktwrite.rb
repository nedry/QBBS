#############################################
#											
#   t_pktwrite.rb --Outgoing Packet Processor for Fidomail tosser for QBBS.		                                
#   (C) Copyright 2004, Fly-By-Night Software (Ruby Version)                        
#                                                                                                            
############################################## 

include Logger
#require "postgres"
require "tools.rb"
require "consts.rb"
require "t_class.rb"
require "t_const.rb"
require "db/db_class.rb"
require "db/db_area"
require "db/db_message"
require "db"


require 'fidomail_packet_writer.rb'

include Logger



def pkt_export_run
  pkt_writer = FidomailPacketWriter.new(@happy)
  user = fetch_user(get_uid(FIDOUSER))
  puts user.name
  #clearoldrep
  puts "-FIDO: Starting export."
  #open_database
  add_log_entry(2,Time.now,"Starting Fido message export.")
  packet_filename = "#{Time.now.to_i.to_s(16)}.pkt"
  open_pkt("#{TEMPOUTDIR}/#{packet_filename}")
  pkt_writer.create_pkt_header
  xport = fido_export_lst
  #rewritereplog
  total = 0
  xport.each {|xp|
    area = fetch_area(xp.num)
    puts "-FIDO: Now Processing #{area.name} area."

    #on first run with database... the user might not have logged in...
    user.lastread ||= []

    pointer = user.lastread[xp.num] || 0
    #puts "-FIDO: Last [absolute] Exported Message...#{pointer}"
    #puts "-FIDO: Highest [absolute] Message.........#{high_absolute(area.tbl)}"
    #puts "-FIDO: Total Messages.....................#{m_total(area.tbl)}"
    new = new_messages(area.tbl,pointer)
    puts "-FIDO: Messages to Export.................#{new}"
    puts 

    if new > 0

      for i in pointer.succ..high_absolute(area.tbl) do
        workingmessage = fetch_msg(area.tbl,i)
        if workingmessage
          if !workingmessage.f_network and !workingmessage.exported
            pkt_writer.convert_a_message(area.tbl,area.fido_net,workingmessage)
            total += 1
            exported(area.tbl,workingmessage.number)
          else
            error = workingmessage.network ?
              "Message has already been imported.":
              "Message [#{i}] doesn't exist."
            m = "Message #{i} not exported.  #{error}"
            #replogandputs "-#{m}"

          end
        end
        puts "-FIDO: Updating message pointer for board #{xp.table}"
        n = xp.num
        user.lastread[n] = high_absolute(area.tbl)
        update_user(user,get_uid(FIDOUSER))
      end
    end
  }
  pkt_writer.write_pkt_end
  @happy.close


  if total == 0
    system("rm #{TEMPOUTDIR}/#{packet_filename}") 
    puts "-FIDO: No messages to export.  Deleting Packet."
    add_log_entry(2,Time.now,"No messages to export.  Deleting Packet #{packet_filename}.")
  else
    puts "-FIDO: Export Complete, #{total} messaged exported."
    add_log_entry(2,Time.now,"Export Complete #{total} message(s) exported.")

    bundle
  end

  return total
end
