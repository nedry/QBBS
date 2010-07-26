class Group
  include DataMapper::Resource

  property :grp, Serial
  property :number, Integer,  :min => 0, :max => 2**32
  property :delete, Boolean, :default => false
  property :locked, Boolean, :default => false
  property :groupname, String, :length => 40
   has n, :areas,  :child_key => [:grp]
   has n, :qwknets, :child_key => [:grp]
end
