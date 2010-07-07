class Group
  include DataMapper::Resource

  property :grp, Serial
  property :groupname, String, :length => 40
   has n, :areas,  :child_key => [:grp]
end
