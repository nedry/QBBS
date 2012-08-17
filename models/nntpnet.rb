require 'models/group'

class Nntpnet
  include DataMapper::Resource

  property :nntp_id, Serial
  property :name, String, :length => 40
  property :delete, Boolean, :default => false
  property :locked, Boolean, :default => false
  #property :number, Integer, :required => true
  property :modify_date, DateTime
  property :nntpuser, String, :length => 40
  property :nntptag, String, :length => 255
  property :nntpinterval, Integer, :default => 15
  property :nntpaddress, String, :length => 60
  property :nntpaccount, String, :length => 40
  property :nntppassword, String, :length => 40
  property :grp, Integer, :default => 1, :min => 0, :max => 2**32
  belongs_to :group, :child_key => [:grp]
  

end
