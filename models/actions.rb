class Actions
  include DataMapper::Resource
  storage_names[:default] = 'actions'

  property :id, Serial
  property :created, DateTime
  propterty :name, String, :length => 40
  property :action, String, :length => 80 

end
