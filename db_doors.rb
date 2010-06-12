
def d_total

  res = @db.query("SELECT COUNT(*) FROM doors")
  result = single_result(res).to_i
  return result
end

def create_door_table

  puts "-DB: Creating Doors Table"
  @db.exec("CREATE TABLE doors (name varchar(40), \
  locked boolean DEFAULT false, number int, \
  modify_date timestamp, d_path varchar(40),\
  d_type varchar(10), path varchar(40),\
  level int DEFAULT 0, droptype varchar(10) DEFAULT 'RBBS', id serial PRIMARY KEY)")

end

def delete_door(ind)

  @db.exec("DELETE FROM doors WHERE number = '#{ind}'")
end

def update_door(r)

  r.name.gsub!("'",QUOTE) if r.name != nil
  r.d_path.gsub!("'",QUOTE) if r.d_path != nil
  r.path.gsub!("'",QUOTE) if r.path != nil
  r.d_type.gsub!("'",QUOTE) if r.d_type != nil
  r.droptype.gsub!("'",QUOTE) if r.droptype != nil

  @db.exec("UPDATE doors SET name = '#{r.name}', \
  locked = #{r.locked}, modify_date = '#{r.modify_date}', \
  d_path = '#{r.d_path}', path = '#{r.path}',d_type = '#{r.d_type}', \
  droptype = '#{r.droptype}' WHERE number = #{r.number}")

end

def fetch_door(record)

  res = @db.exec("SELECT * FROM doors WHERE number = #{record}")

  temp = result_as_array(res).flatten

  t_name = temp[0]
  t_locked = db_true(temp[1])
  t_number = temp[2].to_i
  t_modify_date = temp[3]
  t_d_path= temp[4]
  t_d_type = temp[5]
  t_path = temp[6]
  t_level = temp[7].to_i
  t_droptype = temp[8]

  t_name.gsub!(QUOTE,"'") if t_name != nil
  t_d_path.gsub!(QUOTE,"'") if t_d_path != nil
  t_d_type.gsub!(QUOTE,"'") if t_d_type != nil
  t_path.gsub!(QUOTE,"'") if t_path != nil
  t_droptype.gsub!(QUOTE,"'") if t_droptype != nil

  result = DB_doors.new( t_name,t_locked,t_number, \
  t_modify_date,t_d_path, \
  t_d_type,t_path,t_level,t_droptype)
  return result


end

def renumber_doors

  if d_total > 0 then
    hash = hash_table("doors")

    for i in 0..hash.length - 1
      puts("UPDATE doors SET number = #{i+1} WHERE id = #{hash[i]}")
      @db.exec("UPDATE doors SET number = #{i+1} WHERE id = #{hash[i]}")
    end
  end
end

def add_door(name, path)

  number = d_total + 1

  name.gsub!("'",QUOTE)
  path.gsub!("'",QUOTE)

  date = Time.now.strftime("%m/%d/%Y %I:%M%p")

  @db.exec("INSERT INTO doors (name, number, modify_date, \
  path) VALUES ('#{name}', #{number}, '#{date}', '#{path}')")

end



