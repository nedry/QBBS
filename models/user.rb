class User
  include DataMapper::Resource
  property :number, Serial
  property :deleted, Boolean, :default => false
  property :locked, Boolean, :default => false
  property :name, String, :length => 40
  property :alias, String, :length => 40
  property :ip, String, :length => 20 
  property :citystate, String, :length => 40
  property :address, String, :length => 40
  property :password, String, :length => 20 
  property :length, Integer
  property :modify_date, Date
  property :width, Integer
  property :ansi, Boolean
  property :more, Boolean
  property :level, Integer
  property :area_access, Text
  property :lastread, Text
  property :create_date, Date
  property :laston, Date 
  property :logons, Integer
  property :posted, Integer
  property :rsts_pw, String, :length => 40
  property :rsts_acc, Integer 
  property :fullscreen, Boolean
  property :zipread, Text
  property :signature, Text

  has_one :who, :child_key => [:number]
end
