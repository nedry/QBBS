require 'models/numbered'

class Bulletin
  include DataMapper::Resource
  extend Numbered

  property :id, Serial
  property :name, String, :length => 40
  property :locked, Boolean, :default => false
  property :number, Integer
  property :modify_date, DateTime
  property :path, String, :length => 40, :field => 'b_path'
end
