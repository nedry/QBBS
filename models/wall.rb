class Wall
  include DataMapper::Resource
  storage_names[:default] = 'wall'

  property :number, Serial
  property :uid, Integer
  property :l_type, String, :length => 40
  property :timeposted, Date
end
