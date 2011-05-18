#############################################
#											
#   t_pktwrite.rb --Outgoing Packet Processor for Fidomail tosser for QBBS.		                                
#   (C) Copyright 2004, Fly-By-Night Software (Ruby Version)                        
#                                                                                                            
############################################## 

include Logger
require "tools.rb"
require "consts.rb"
require "t_class.rb"
require "t_const.rb"
require "db/db_area"
require "db/db_message"



require 'fidomail_packet_writer.rb'

include Logger



def pkt_export_run
 
  user = fetch_user(get_uid(FIDOUSER))
  scanforaccess(user)
  #clearoldrep
  puts "-FIDO: Starting export."

  add_log_entry(2,Time.now,"Starting Fido message export.")
  packet_filename = "#{Time.now.to_i.to_s(16)}.pkt"
  
  pkt_writer = FidomailPacketWriter.new(@writer)
  pkt_writer.open_pkt("#{TEMPOUTDIR}/#{packet_filename}")
  pkt_writer.create_pkt_header
  xport = fido_export_lst
  #rewritereplog
  total = 0
  xport.each {|xp|

    pointer = get_pointer(user,xp.number)
    puts "-FIDO: Now Processing #{xp.name} area."

    puts "-FIDO: Last [absolute] Exported Message...#{pointer.lastread}"
    puts "-FIDO: Highest [absolute] Message.........#{high_absolute(xp.number)}"
    puts "-FIDO: Total Messages.....................#{m_total(xp.number)}"
    new = new_messages(xp.number,pointer.lastread)
    puts "-FIDO: Messages to Export.................#{new}"
    puts 

    if new > 0
     export_messages(xp.number,pointer.lastread).each_with_index {|msg,i|

          if !msg.f_network and !msg.exported then
            pkt_writer.write_a_message(xp.number,xp.fido_net,msg)
            total += 1
	    msg.exported = true
	    update_msg(msg)

          else
            error = msg.network ?
              "Message has already been imported.":
              "Message [#{i}] doesn't exist."
            m = "Message #{i} not exported.  #{error}"
            #replogandputs "-#{m}"

          end

     }
        puts "-FIDO: Updating message pointer for board #{xp.name}"

        pointer.lastread = high_absolute(xp.number)
        update_pointer(pointer)

    end
  }
  pkt_writer.write_pkt_end



  if total == 0
    system("rm #{TEMPOUTDIR}/#{packet_filename}") 
    puts "-FIDO: No messages to export.  Deleting Packet."
    add_log_entry(L_FIDO,Time.now,"No msg to export. Del Pkt #{packet_filename}.")
  else
    puts "-FIDO: Export Complete, #{total} messaged exported."
    add_log_entry(L_FIDO,Time.now,"Export Complete #{total} message(s) exported.")

    bundle
  end

  return total
end
