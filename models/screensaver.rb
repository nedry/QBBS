require 'models/numbered'

class Screensaver
  include DataMapper::Resource
  extend Numbered

  property :screen_key, Serial
  property :name, String, :length => 40
  property :locked, Boolean, :default => false 
  property :number, Integer
  property :modify_date, DateTime
  property :d_path, String, :length => 40
  property :d_type, String, :length => 10 
  property :path, String, :length => 40
  property :level, Integer, :default => 0 
  property :droptype, String, :length => 10, :default => 'RBBS'
   has n, :users, :child_key => [:screen_key]
end
