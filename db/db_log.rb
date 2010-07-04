
require 'models/log'
require 'models/subsystem'

def clearlog
  Ulog.destroy!
end



def add_log_entry(subsystem,ent_date,message)
  Ulog.new(:subsystem => subsystem, :ent_date  => ent_date, :message => message).save!
end



def fetch_log(sys)
  result = Ulog.all(:order => [ :ent_date.desc ])
  return result
end

def log_empty

  result = true
  temp = Ulog.count
  result = false if temp > 0 
  return result
end

def log_size
  Ulog.count
end
