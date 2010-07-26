require 'models/numbered'

class Door
  include DataMapper::Resource
  extend Numbered

  property :id, Serial
  property :name, String, :length => 40
  property :locked, Boolean, :default => false 
  property :number, Integer
  property :modify_date, DateTime
  property :d_path, String, :length => 40
  property :d_type, String, :length => 10 
  property :path, String, :length => 40
  property :level, Integer, :default => 0 
  property :droptype, String, :length => 10, :default => 'RBBS'
end
