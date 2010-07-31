class Subsys
  include DataMapper::Resource
  storage_names[:default] = 'subsys'
  property :id, Serial
  property :subsystem, Integer
  property :name, String, :length => 40
  
 has n, :ulogs,  :child_key => [:subsystem]
end
