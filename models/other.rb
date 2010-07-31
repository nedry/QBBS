require 'models/numbered'

class Other
  include DataMapper::Resource
  extend Numbered
  storage_names[:default] = 'other'

  property :id, Serial
  property :name, String, :length => 40
  property :locked, Boolean, :default => false
  property :number, Integer
  property :modify_date, DateTime
  property :address, String, :length => 40
  property :level, Integer, :default => 0
end
