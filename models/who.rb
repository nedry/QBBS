class Who
  include DataMapper::Resource
  storage_names[:default] = 'who'

  property :id, Serial
  property :number, Integer, :min => 0, :max => 2**32, :key => true
  property :lastactivity, DateTime
  property :place, String, :length => 40

belongs_to :user, :child_key => [:number]

end
