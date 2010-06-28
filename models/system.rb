class System
  include DataMapper::Resource

  property :id, Serial
  property :lastqwkrep, DateTime
  property :qwkrepsuccess, Boolean 
  property :qwkrepwake, DateTime
  property :rec, Integer, :default => 1  
  property :f_msgid, Integer, :min => 0, :max => 2**32
end
