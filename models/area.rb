require 'models/group'
require 'models/message'

class Area
  include DataMapper::Resource

 #property :area_key, Serial
  property :name, String, :length => 40
  property :delete, Boolean, :default => false
  property :locked, Boolean, :default => false
  property :number, Integer, :required => true, :key => true
  property :netnum, Integer, :default => -1
  property :d_access, String, :length => 1
  property :v_access, String, :length => 1
  property :modify_date, DateTime
  property :network, String, :length => 40
  property :fido_net, String, :length => 40
  property :nntp_net, String, :length => 40
	property :mbbs_net, String, :length => 40
  property :nntp_pointer, Integer, :default => 0, :min => 0, :max => 2**32
  property :grp, Integer, :default => 1, :min => 0, :max => 2**32
  property :prune, Integer, :default => 1, :min => 0, :max => 2**32
  has n, :messages, :child_key => [:number]
  belongs_to :group, :child_key => [:grp]

end
