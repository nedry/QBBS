
require 'models/log'
require 'models/subsystem'

def clearlog
  Ulog.destroy!
end



def add_log_entry(subsystem,ent_date,message)

 # @db.exec("INSERT INTO log (subsystem,ent_date,message) VALUES ('#{subsystem}', '#{ent_date}', '#{message}')") 
  Ulog.new(:subsystem => subsystem, :ent_date  => ent_date, :message => message).save!


end



def fetch_log(sys)
  res = @db.exec("SELECT subsys.name,ent_date,message from log INNER JOIN subsys ON subsys.subsystem = log.subsystem ORDER BY ent_date DESC ") 
  result = result_as_array(res)
  t_log = Ulog.all(:order => [ :ent_date.desc ])
  puts t_log.each {|x| puts "Dude, this is the shit:#{x.ent_date}: #{x.message}: #{x.subsys.name}"}
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
