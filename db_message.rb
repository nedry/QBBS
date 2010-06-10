


def m_total(table)

 res = @db.exec("SELECT COUNT(*) FROM #{table}")
 result = single_result(res).to_i
 return result
end

def create_msg_table(table)

 puts "-DB: Creating Message Table #{table}"
 #begin
  @db.exec("CREATE TABLE #{table} (delete boolean DEFAULT false, \
           locked boolean DEFAULT false, number bigserial PRIMARY KEY, \
            m_to varchar(40), \
           m_from varchar(40), msg_date timestamp, subject varchar(80),\
           msg_text text, exported boolean DEFAULT false,\
	   network boolean DEFAULT false, f_network boolean DEFAULT false, orgnode int, destnode int,\
	   orgnet int, destnet int, attribute int, cost int, area varchar(80), \
	   msgid varchar(80), path varchar(80),\
	   tzutc varchar(10), charset varchar(10), tid varchar(80), \
	   pid varchar(80), intl varchar(80), topt int,\
	   fmpt int, reply boolean, origin varchar(80),smtp boolean DEFAULT false )")
	   

 #rescue
 # puts "-DB: Error Creating Message Table #{table}"
 #end
end



 
def new_messages(table,ind)

#puts "ind:#{ind}"
   ind = 0 if ind.nil?

 res = @db.exec("SELECT COUNT(*) FROM #{table} WHERE number > #{ind}")
 result = single_result(res).to_i
end
 
def get_pointer(table,ind)

   pointer = m_total(table)

end

def absolute_message(table,ind)
   ind = 0 if ind.nil?
   @db.exec("BEGIN")
   @db.exec("DECLARE c CURSOR FOR SELECT number FROM #{table} ORDER BY number")
   @db.exec("MOVE FORWARD #{ind+1} IN c")
   res =  @db.query("FETCH BACKWARD 1 IN c")
   result = single_result(res).to_i
   @db.exec("CLOSE c")
   @db.exec("END")
   return result
end

def high_absolute(table)

if m_total(table) > 0 then
 result = absolute_message(table,m_total(table))
else result = 0 end
  
 return result
end

def delete_msg(table,ind)

 @db.exec("DELETE FROM #{table} WHERE number = '#{ind}'")
end

def delete_msgs(table,first,last)

 @db.exec("DELETE FROM #{table} WHERE number >= '#{first}' and number <= '#{last}'")
end

def find_fido_area (area)

 table = nil
 area.strip! if !area.nil?
 res = @db.exec("SELECT tbl,number FROM areas WHERE fido_net = '#{area}'")
 temp = result_as_array(res).flatten
 table = temp[0]
 number = temp[1].to_i
 return [table,number]
end

def exported(table,number)
 @db.exec("UPDATE #{table} SET exported = true WHERE number = #{number}")
end

def update_msg(table,r)
 

 @db.exec("UPDATE #{table} SET delete = '#{r.delete}',\
           locked = '#{r.locked}', \
           to = '#{r.m_to}', from = '#{r.m_from}',\
           subject = '#{r.subject}', \
           msg_date = '#{r.msg_date}', \
           msg_text = '#{r.msg_text}', \
           exported = '#{r.exported}', \ 
           network = '#{r.network}',\
           f_network = '#{f_network}',\
           orgnode = '#{r.orgnode}',\
           destnode = '#{r.destnode}'\
           orgnet = '#{r.orgnet}',\
           destnet = '#{r.destnet}',\
           attribute = '#{r.attribute}',\
           cost = '#{r.cost}',\
           area = '#{r.area}',\
           msgid = '#{r.msgid}',\
           path = '#{r.path}',\
           tzutc = '#{r.tzutc}',\
           charset = '#{r.charset}',\
           tid = '#{r.tid}',\
           pid = '#{r.pid}',\
           intl = '#{r.intl}',\
           topt = '#{r.topt}',\
           fmpt = '#{r.fmtp}',\
           reply = '#{r.reply}',\
           origin = '#{r.origin}',\
           smtp = '#{r.smtp}'\
           WHERE number = #{r.number}")
 end


def fetch_msg(table, record)

worked = false

res = @db.exec("SELECT * FROM #{table} WHERE number = #{record}") 
temp = result_as_array(res).flatten
  
  t_delete		= db_true(temp[0])

  t_locked	 	= db_true(temp[1])
  t_number	= temp[2].to_i
  t_m_to	 	= temp[3]
  t_m_from	= temp[4]
  t_msg_date	= temp[5]
  t_subject	= temp[6]
  t_msg_text	= temp[7]
  t_exported	= db_true(temp[8])
  t_network	= db_true(temp[9])
  t_f_network	= db_true(temp[10])
  
  t_orgnode 	= temp[11].to_i
  t_destnode 	= temp[12].to_i
  t_orgnet 	= temp[13].to_i
  t_destnet 	= temp[14].to_i
  t_attribute 	= temp[15].to_i
  t_cost 		= temp[16].to_i
  t_area 		= temp[17]
  t_msgid 		= temp[18]
  t_path 		= temp[19]
  t_tzutc 		= temp[20]
  t_charset 	= temp[21]
  t_tid 		= temp[22]
  t_pid 		= temp[23]
  t_intl 		= temp[24]
  t_topt 		= temp[25].to_i
  t_fmpt 		= temp[26].to_i
  t_reply		= db_true(temp[27])
  t_origin		= temp[28]
  t_smtp		= db_true(temp[29])
  
  t_topt = nil if t_topt == -1
  t_destnode = nil if t_destnode == -1
  t_destnet = nil if t_destnet == -1

  t_m_to.gsub!(QUOTE,"'") if t_m_to != nil
  t_m_from.gsub!(QUOTE,"'") if t_m_from != nil
  t_subject.gsub!(QUOTE,"'") if t_subject != nil
  t_msg_text.gsub!(QUOTE,"'") if t_msg_text != nil
  
  worked             = true
  
 
if worked then 
 result = DB_message.new(t_delete, t_locked,t_number, t_m_to,t_m_from, 
				 t_msg_date,t_subject, t_msg_text,t_exported,t_network,t_f_network,
				 t_orgnode,t_destnode,t_orgnet,t_destnet,t_attribute,t_cost,
				 t_area,t_msgid,t_path,t_tzutc,t_charset,t_tid,t_pid,t_intl,
				 t_topt,t_fmpt,t_reply,t_origin,t_smtp) 	
				 
else 
 result = nil
end
 return result
end




def add_msg(table, m_to,m_from,msg_date,subject,msg_text,exported,network,reply,destnode,destnet,intl,topt,smtp)

 #number = high_absolute(table) + 1  
 
 #puts "number: #{number}"


 msg_text.gsub!("'",QUOTE) if msg_text != nil
 m_to.gsub!("'",QUOTE) if m_to != nil
 m_from.gsub!("'",QUOTE) if m_from != nil
 subject.gsub!("'",QUOTE) if subject != nil
 topt = -1 if topt.nil?
 destnode = -1 if destnode.nil?
 destnet = -1 if destnet.nil?
 
#puts("INSERT INTO #{table} (m_to, m_from, \ 
#           msg_date, subject, msg_text, exported,network,reply,destnet,destnode,intl,topt,smtp) VALUES \ 
#         ('#{m_to}', '#{m_from}', '#{msg_date}', '#{subject}',\
#	  '#{msg_text}', '#{exported}','#{network}','#{reply}',\
#	  '#{destnet}','#{destnode}','#{intl}','#{topt}','#{smtp}')") 


 @db.exec("INSERT INTO #{table} (m_to, m_from, \ 
           msg_date, subject, msg_text, exported,network,reply,destnet,destnode,intl,topt,smtp) VALUES \ 
          ('#{m_to}', '#{m_from}', '#{msg_date}', '#{subject}',\
	  '#{msg_text}', '#{exported}','#{network}','#{reply}',\
	  '#{destnet}','#{destnode}','#{intl}','#{topt}','#{smtp}')") 

return high_absolute(table)
end


 
