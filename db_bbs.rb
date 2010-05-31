
def o_total

  res = @db.exec("SELECT COUNT(*) FROM other")
  result = single_result(res).to_i
  return result
end

def create_other_table

  puts "-DB: Creating Other Table"
  @db.exec("CREATE TABLE other (name varchar(40), \
        locked boolean DEFAULT false, number int, \
           modify_date timestamp, address varchar(40),\
                  level int DEFAULT 0,  id serial PRIMARY KEY)")

end

def delete_other(ind)

  @db.exec("DELETE FROM other WHERE number = '#{ind}'")
end

def update_other(r)

  r.name.gsub!("'",QUOTE) if r.name != nil
  r.address.gsub!("'",QUOTE) if r.address != nil

  @db.exec("UPDATE other SET name = '#{r.name}', \
           locked = #{r.locked}, modify_date = '#{r.modify_date}', \
           address = '#{r.address}', WHERE number = #{r.number}")

end

def fetch_other(record)

  res =  @db.exec("SELECT * FROM other WHERE number = #{record}") 

  temp = result_as_array(res).flatten

  t_name 			= temp[0]
  t_locked 			= db_true(temp[1])
  t_number 		= temp[2].to_i
  t_modify_date 	= temp[3]
  t_address		= temp[4]
  t_level 			= temp[5].to_i

  t_name.gsub!(QUOTE,"'") if t_name != nil
  t_address.gsub!(QUOTE,"'") if t_address != nil

  result = DB_other.new( t_name,t_locked,t_number, \
                        t_modify_date,t_address, t_level)
  return result
end



def renumber_other

  if d_total > 0 then
    hash = hash_table("other")

    for i in 0..hash.length - 1
      puts("UPDATE other SET number = #{i+1} WHERE id = #{hash[i]}")
      @db.exec("UPDATE other SET number = #{i+1} WHERE id = #{hash[i]}")
    end
  end
end

def add_other(name, address)

  number = o_total + 1  

  name.gsub!("'",QUOTE)
  address.gsub!("'",QUOTE)

  date = Time.now.strftime("%m/%d/%Y %I:%M%p")

  @db.exec("INSERT INTO other (name, number, modify_date, \
                  address) VALUES ('#{name}', #{number}, '#{date}', '#{address}')")

end



