class Who
  include DataMapper::Resource

  property :id, Serial
  property :number, Integer, :min => 0, :max => 2**32
  property :lastactivity, DateTime
  property :place, String, :length => 40

  belongs_to :user, :child_key => [:number]
end
