class Who_t
  include DataMapper::Resource
  storage_names[:default] = 'who_t'

  property :id, Serial
  property :irc, Boolean
  property :node, Integer
  property :location, String, :length => 40
  property :where, String, :length => 40
  property :wh, String, :length => 40
  #property :page, Text
  property :name, String, :length => 40
  property :number, Integer, :min => 0, :max => 2**32
end
