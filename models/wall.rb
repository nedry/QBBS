class Wall
  include DataMapper::Resource
  storage_names[:default] = 'wall'
  property :id, Serial
  property :number, Integer, :key => true
 # property :uid, Integer
  property :message, Text
  property :l_type, String, :length => 40
  property :timeposted, DateTime
  belongs_to :user, :child_key => [:number]

 
end
