def create_wall_table

  puts "-DB: Creating Wall Table"
  @db.exec("CREATE TABLE wall (uid BigInt, number BigSerial Primary Key, timeposted timestamp, \
  message text, l_type varchar(40))")

end


def delete_wall(number)
  @db.exec("Delete from wall where number = '#{number}'")
end

def add_wall(uid,timeposted,message,l_type)

  @db.exec("INSERT INTO wall (uid,timeposted,message,l_type) \
  VALUES ('#{uid}', '#{timeposted}', '#{message}', '#{l_type}')")

end



def fetch_wall
  res = @db.exec("SELECT users.name,timeposted, message, l_type, wall.number FROM wall LEFT OUTER JOIN users ON wall.uid=users.number ORDER BY timeposted DESC ")
  result = result_as_array(res)
  return result
end



def wall_cull
  list = fetch_wall
  for i in 0..list.length - 1
    test = list[i]
    delete_wall(test[4])  if i > 10
  end
end

def wall_empty

  result = false

  res = @db.exec("SELECT COUNT(*) FROM wall")
  temp = single_result(res).to_i
  result = true if temp == 0
  return result
end
