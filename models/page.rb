class Page
  include DataMapper::Resource

  property :id, Serial
  property :number, Integer, :min => 0, :max => 2**32, :key => true
  property :from, Integer, :min => 0, :max => 2**32
  property :system, Boolean, :default => false
  property :left_at, DateTime, :default => Time.now
  property :message, String, :length => 254
  belongs_to :user, :child_key => [:number]

end
