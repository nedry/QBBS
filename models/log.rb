class Ulog
  include DataMapper::Resource
  storage_names[:default] = 'log'
  property :id, Serial
  property :subsystem, Integer, :key => true
  property :ent_date, DateTime
  property :message, String, :length => 255
     belongs_to :subsys, :child_key => [:subsystem]


end

