class Bulletin
  include DataMapper::Resource

  property :id, Serial
  property :name, String, :length => 40
  property :locked, Boolean, :default => false
  property :number, Integer
  property :modify_date, DateTime
  property :b_path, String, :length => 40
end
