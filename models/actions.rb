class Actions
  include DataMapper::Resource
  storage_names[:default] = 'actions'

  property :id, Serial
  property :created, DateTime
  property :name, String, :length => 10
  property :number, Integer, :required => true, :key => true
  property :modify_date, DateTime
  property :action, String, :length => 80 
  property :local_action, String, :length => 80
  property :me_action, String, :length => 80
  property :directed, Boolean

end
