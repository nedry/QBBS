def create_group_table

  puts "-DB: Creating Group Table"
  @db.exec("CREATE TABLE groups (number bigserial PRIMARY KEY, groupname varchar(40))")

  @db.exec("INSERT INTO groups (groupname) VALUES ('Local')")
  @db.exec("INSERT INTO groups (groupname) VALUES ('DoveNet')")
  @db.exec("INSERT INTO groups (groupname) VALUES ('FidoNet')")
end

def update_groups(number,name)
  g = Group.first(:number => number)
  g.update(:groupname => name)
end

def fetch_groups
  Group.all(:order => number)
end
