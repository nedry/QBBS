
def a_total

 res = @db.exec("SELECT COUNT(*) FROM areas")
 result = single_result(res).to_i
 return result
end

def create_area_table

 puts "-DB: Creating Area Table"
 @db.exec("CREATE TABLE areas (area_key SERIAL PRIMARY KEY, name varchar(40), \
           tbl varchar(10), delete boolean DEFAULT false, \
           locked boolean DEFAULT false, number int NOT NULL, \
           netnum int DEFAULT -1, d_access char(1), \
           v_access char(1), modify_date date, \
           network varchar(40), fido_net varchar(40),grp bigint DEFAULT 1)")

 add_area("Email","email","I","I")
 create_msg_table("email")
 add_area("General Discussions","general","W","W")
  create_msg_table("general")
end

def update_group(r)
 @db.exec("UPDATE areas SET grp = '#{r.group}' WHERE number = #{r.number}")
end

def update_area(r)

 r.name.gsub!("'",QUOTE) if r.name != nil
 r.tbl.gsub!("'",QUOTE) if r.tbl != nil
 r.network.gsub!("'",QUOTE) if r.network != nil
 
 @db.exec("UPDATE areas SET name = '#{r.name}', \
           tbl = '#{r.tbl}', delete = #{r.delete}, \
           locked = #{r.locked}, netnum = #{r.netnum},\
           d_access = '#{r.d_access}', \
           v_access = '#{r.v_access}', \
           modify_date = '#{r.modify_date}', \
           network = '#{r.network}', fido_net = '#{r.fido_net}'\	   
           WHERE number = #{r.number}")
 end

def fetch_area(record)

res = @db.exec("SELECT areas.name, areas.tbl, areas.delete, areas.locked, \
		      areas.number, areas.netnum, areas.d_access, areas.v_access,\
		      areas.modify_date, areas.network, areas.fido_net, groups.groupname \
		      FROM areas,groups WHERE areas.grp = groups.number and areas.number = #{record}") 
		      
temp = result_as_array(res).flatten

 t_name 			= temp[0]
 t_table 			= temp[1]
 t_delete 			= db_true(temp[2])
 t_locked 			= db_true(temp[3])
 t_number 		= temp[4].to_i
 t_netnum 		= temp[5].to_i
 t_d_access 		= temp[6]
 t_v_access 		= temp[7]
 t_modify_date 	= temp[8]
 t_network 		= temp[9]
 t_fido_net 		= temp[10]
 t_group 			= temp[11]
 
 t_name.gsub!(QUOTE,"'") if t_name != nil
 t_table.gsub!(QUOTE,"'")if t_table != nil
 
 result = DB_area.new(t_name,t_table,t_delete, \
                      t_locked,t_number,t_netnum, \
                      t_d_access,t_v_access, \
                      t_modify_date,t_network,t_fido_net,t_group)
 return result
end



def fetch_area_list(num)

 a_list = []
 
 out = nil
 out = " and areas.grp = '#{num}'" if !num.nil?
 
 res = @db.exec("SELECT areas.name,areas.delete,areas.number,groups.groupname,areas.tbl \
		       FROM areas,groups WHERE areas.grp = groups.number #{out} ORDER BY areas.grp,areas.number")
		       
 temp = result_as_array(res)

 for i in 0..temp.length - 1 do
   t_name		= temp[i][0]
   t_delete	= db_true(temp[i][1])
   t_number	= temp[i][2].to_i
   t_group		= temp[i][3]
   t_tbl		= temp[i][4]
  a_list << DB_area_list.new(t_name,t_delete,t_number,t_group,t_tbl)
end

return a_list

end

def find_qwk_area (number,name)  # name for future use.

 result = nil

 res = @db.exec("SELECT number FROM areas WHERE netnum = #{number}")
 result = single_result(res).to_i if !single_result(res).nil?
 return result
end

def add_area(name, tbl, d_access,v_access)

 number = a_total  #area's start with 0, so the total will be the next area
 
 name.gsub!("'",QUOTE)
 tbl.gsub!("'",QUOTE)
 puts current_date
 @db.exec("INSERT INTO areas (name, tbl, number, d_access, v_access, \ 
           modify_date) VALUES ('#{name}', '#{tbl}', #{number} ,\
           '#{d_access}', '#{v_access}', '#{current_date}')") 
	   


end
 

 
