class Ulog
  include DataMapper::Resource
  storage_names[:default] = 'log'
  property :id, Serial
  property :subsystem, Integer
  property :ent_date, DateTime
  property :message, String, :length => 60
  
   belongs_to :subsys, :child_key => [:subsystem]
end

