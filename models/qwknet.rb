require 'models/group'

class Qwknet
  include DataMapper::Resource

  property :qwk_id, Serial
  property :name, String, :length => 40
  property :delete, Boolean, :default => false
  property :locked, Boolean, :default => false
  #property :number, Integer, :required => true
  property :modify_date, DateTime
  property :repdata, String, :length => 40
  property :qwkuser, String, :length => 40
  property :bbsid, String, :length => 40
  property :reppacket, String, :length => 40
  property :repdir, String, :length => 40
  property :qwkpacket, String, :length => 40
  property :qwkdir, String, :length => 40
  property :qwkmail, Integer, :default => 0
  property :qwktag, String, :length => 255
  property :qwkinterval, Integer, :default => 15
  property :ftpaddress, String, :length => 60
  property :ftpaccount, String, :length => 40
  property :ftppassword, String, :length => 40
  property :grp, Integer, :default => 1, :min => 0, :max => 2**32
  belongs_to :group, :child_key => [:grp]
  has n, :qwkroutes, :child_key => [:qwk_id]

end
