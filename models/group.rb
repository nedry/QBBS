class Group
  include DataMapper::Resource

  property :number, Serial
  property :groupname, String, :length => 40
end
