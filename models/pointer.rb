class Pointer
  include DataMapper::Resource
 # storage_names[:default] = 'pointer'

  property :id, Serial
  property :number, Integer, :min => 0, :max => 2**32, :key => true
  property :lastread, Integer, :min => 0, :max => 2**32
  property :access, String, :length => 1
  property :zipread, Boolean, :default => true
  belongs_to :user, :child_key => [:number]

end
