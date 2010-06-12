
def create_subsystem_table
  puts "-DB: Creating the Subsystem Log Table"
  @db.exec("CREATE TABLE subsys (subsystem Integer, name varchar(80))")
  @db.exec("INSERT INTO subsys (subsystem,name) VALUES ('1','SCHEDULE')")
  @db.exec("INSERT INTO subsys (subsystem,name) VALUES ('2','FIDO')")
  @db.exec("INSERT INTO subsys (subsystem,name) VALUES ('3','EXPORT')")
  @db.exec("INSERT INTO subsys (subsystem,name) VALUES ('4','IMPORT')")
  @db.exec("INSERT INTO subsys (subsystem,name) VALUES ('5','USER')")
  @db.exec("INSERT INTO subsys (subsystem,name) VALUES ('6','CONNECT')")
  @db.exec("INSERT INTO subsys (subsystem,name) VALUES ('7','SECURITY')")
  @db.exec("INSERT INTO subsys (subsystem,name) VALUES ('8','ERROR')")
  @db.exec("INSERT INTO subsys (subsystem,name) VALUES ('9','MESSAGE')")


end


def create_log_table

  puts "-DB: Creating the System Log Table"
  @db.exec("CREATE TABLE log (subsystem Integer, ent_date timestamp, message varchar(80))")

end


def clearlog
  @db.exec("Delete from log")
end



def add_log_entry(subsystem,ent_date,message)

  @db.exec("INSERT INTO log (subsystem,ent_date,message) VALUES ('#{subsystem}', '#{ent_date}', '#{message}')")

end



def fetch_log(sys)
  res = @db.exec("SELECT subsys.name,ent_date,message from log INNER JOIN subsys ON subsys.subsystem = log.subsystem ORDER BY ent_date DESC ")
  result = result_as_array(res)

  return result
end

def log_empty

  result = true

  res = @db.exec("SELECT COUNT(*) FROM log")
  temp = single_result(res).to_i

  result = false if temp > 0
  return result
end

def log_size

  res = @db.exec("SELECT COUNT(*) FROM log")
  temp = single_result(res).to_i

  return temp
end

