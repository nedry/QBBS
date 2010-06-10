def create_who_table
	
 puts "-DB: Creating Who Table"
 @db.exec("CREATE TABLE who (number BigInt, lastactivity timestamp, \
           place varchar(40))")
	   
end
	

def delete_who(uid)
 @db.exec("Delete from who where number = '#{uid}'")
end

def add_who(number,lastactivity,place)

 @db.exec("INSERT INTO who (number,lastactivity,place) \
  VALUES ('#{number}', '#{lastactivity}', '#{place}')") 
	   
end
 
 def update_who(uid,lastactivity,place)
 

 @db.exec("UPDATE who SET lastactivity = '#{lastactivity}', \
           place = '#{place}' where number= '#{uid}'")
end
   

def fetch_who_list
 res = @db.exec("SELECT users.number, users.name, users.citystate, who.lastactivity, who.place FROM who LEFT OUTER JOIN users ON who.number=users.number ORDER BY users.name ") 
 result = result_as_array(res)
return result
end

def who_exists(uid)

 result = false
  
 res = @db.exec("SELECT COUNT(*) FROM who WHERE number = '#{uid}'")
 temp = single_result(res).to_i
 result = true if temp > 0 
return result
end

 
  def who_list_check
   list = fetch_who_list
   list.each {|x|  delete_who(x[0]) if (Time.now- Time.parse(x[3])) / 60> WEB_IDLE_MAX }
 end
