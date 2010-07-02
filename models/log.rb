class Ulog
  include DataMapper::Resource
  storage_names[:default] = 'log'
  property :id, Serial
  property :subsystem, Integer
  property :ent_date, Date
  property :message, String, :length => 40
  
   has 1, :subsys, :child_key => [:subsystem]
end

