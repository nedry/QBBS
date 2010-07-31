require 'models/group'
require 'models/qwknet'

class Qwkroute
  include DataMapper::Resource

  property :route_id, Serial
  property :qwk_id, Integer
  property :modified, DateTime, :default => Time.now
  property :dest, String, :length => 80
  property :route, String, :length => 255
  belongs_to :qwknet, :child_key => [:qwk_id]


end
