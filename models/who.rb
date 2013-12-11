class Who
  include DataMapper::Resource
  storage_names[:default] = 'who'

  property :id, Serial
  property :number, Integer, :min => 0, :max => 2**32, :key => true
  property :lastactivity, DateTime
  property :sex, String, :length => 5
  property :access, String, :length => 10
  property :time_on, Integer, :min => 0, :max => 2**32
  property :place, String, :length => 40

belongs_to :user, :child_key => [:number]

end
