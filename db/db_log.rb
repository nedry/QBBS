
require 'models/log'
require 'models/subsystem'

def clearlog
  Ulog.destroy!
end

def fetch_subsystems
  Subsys.all(:order => :subsystem)
end

def add_log_entry(subsystem,ent_date,message)
	puts subsystem
	puts ent_date
	puts message
  Ulog.new(:subsystem => subsystem, :ent_date  => ent_date, :message => message).save!
end



def fetch_log(sys)
puts "sys: #{sys}"
  if sys then
    result = Ulog.all(:subsystem => sys, :order => [ :ent_date.desc ])
  else
     result = Ulog.all(:order => [ :ent_date.desc ])
  end
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
