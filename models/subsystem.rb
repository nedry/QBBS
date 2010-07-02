class Subsys
  include DataMapper::Resource
  storage_names[:default] = 'subsys'
  property :id, Serial
  property :subsystem, Integer
  property :name, String, :length => 40
  
  belongs_to :ulog, :required => false   #this stops that stupid constraint.  fuck constraints.
end

