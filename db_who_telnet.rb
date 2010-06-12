
def create_who_t_table

  puts "-DB: Creating Telnet Who_T Table"
  @db.exec("CREATE TABLE who_t (irc Boolean, node Integer, location varchar(40), \
  wh varchar(40), page text, name varchar(40))")

end


def who_delete_t(name)
  @db.exec("Delete from who_t where name = '#{name}'")
end


def delete_irc_t
  @db.exec("Delete from who_t where irc = 'True'")
end

def clear_who_t
  @db.exec("Delete from who_t")
end

def add_who_t(r)

  @db.exec("INSERT INTO who_t (irc, node, location, wh, page, name) \
  VALUES ('#{r.irc}', '#{r.node}', '#{r.location}', '#{r.where}', '#{r.page}','#{r.name}')")

end

#def update_who_t(r)


#@db.exec("UPDATE who_t SET irc = '#{r.irc}', \
#         node = '#{r.node}', location = '#{r.location}', irc = '#{r.irc}', \
#	      wh = '#{r.where}' name = '#{name}'")
#     end

def update_who_t(name,wh)


  @db.exec("UPDATE who_t SET wh = '#{wh}' WHERE name = '#{name}'")
end


def fetch_who_t_list
  res = @db.exec("SELECT * from who_T ORDER BY name ")
  result = result_as_array(res)

  return result
end

def who_t_exists(name)

  result = false

  res = @db.exec("SELECT COUNT(*) FROM who_t WHERE name = '#{name}'")
  temp = single_result(res).to_i
  result = true if temp > 0
  return result
end


