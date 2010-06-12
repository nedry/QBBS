
def b_total

  res = @db.exec("SELECT COUNT(*) FROM bulletins")
  result = single_result(res).to_i
  return result
end

def create_bulletin_table

  puts "-DB: Creating Bulletins Table"
  @db.exec("CREATE TABLE bulletins (name varchar(40), \
  locked boolean DEFAULT false, number int, \
  modify_date timestamp, b_path varchar(40),\
  id serial PRIMARY KEY)")

end

def delete_bulletin(ind)

  @db.exec("DELETE FROM bulletins WHERE number = '#{ind}'")
end

def update_bulletin(r)

  r.name.gsub!("'",QUOTE) if r.name != nil
  r.path.gsub!("'",QUOTE) if r.path != nil

  @db.exec("UPDATE bulletins SET name = '#{r.name}', \
  locked = #{r.locked}, modify_date = '#{r.modify_date}', \
  b_path = '#{r.path}' WHERE number = #{r.number}")
end

def fetch_bulletin(record)

  res = @db.exec("SELECT * FROM bulletins WHERE number = #{record}")

  temp = result_as_array(res).flatten

  t_name = temp[0]
  t_locked = db_true(temp[1])
  t_number = temp[2].to_i
  t_modify_date = temp[3]
  t_path = temp[4]

  t_name.gsub!(QUOTE,"'") if t_name != nil
  t_path.gsub!(QUOTE,"'") if t_path != nil

  result = DB_bulletin.new( t_name,t_locked,t_number, \
  t_modify_date,t_path)
  return result
end



def renumber_bulletins

  if b_total > 0 then
    hash = hash_table("bulletins")

    for i in 0..hash.length - 1
      puts("UPDATE bulletins SET number = #{i+1} WHERE id = #{hash[i]}")
      @db.exec("UPDATE bulletins SET number = #{i+1} WHERE id = #{hash[i]}")
    end
  end
end

def add_bulletin(name, path)

  name.gsub!("'",QUOTE)
  path.gsub!("'",QUOTE)

  number = b_total + 1

  msg_date = Time.now.strftime("%m/%d/%Y %I:%M%p")

  @db.exec("INSERT INTO bulletins (name, number, modify_date, b_path) \
  VALUES ('#{name}', #{number},'#{msg_date}', '#{path}')")

end



