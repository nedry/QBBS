

def create_group_table

  puts "-DB: Creating Group Table"
  @db.exec("CREATE TABLE groups (number bigserial PRIMARY KEY, groupname varchar(40))")

  @db.exec("INSERT INTO groups (groupname) VALUES ('Local')")
  @db.exec("INSERT INTO groups (groupname) VALUES ('DoveNet')")
  @db.exec("INSERT INTO groups (groupname) VALUES ('FidoNet')")
end

def update_groups(number,name)


  @db.exec("UPDATE groups SET groupname = '#{name}' WHERE number = '#{number}'")
end

def fetch_groups

  groups = []

  res = @db.exec("SELECT * FROM groups")

  temp = result_as_array(res)

  for i in 0..temp.length - 1 do
    groups << DB_group.new(temp[i][0].to_i,temp[i][1])
  end
  return groups
end






