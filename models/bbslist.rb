require 'models/numbered'

#We are keeping the field names to match the fields in the
#Synchronet BBS list which this is compatable with.
#So, some names don't make sense...

class Bbslist
  include DataMapper::Resource
  extend Numbered
  storage_names[:default] = 'bbslist'

  property :id, Serial
  property :name, String, :length => 40
  property :locked, Boolean, :default => false
  property :imported, Boolean, :default => false
  property :modify_date, DateTime
  property :born_date, DateTime
  property :software, String, :length => 80
  property :sysop, String, :length => 80
  property :email, String, :length => 80
  property :website, String, :length => 80
  property :number, String, :length => 80
  # meaningless.  I think it was minimum Baud Rate
  property :minrate, String, :length => 80
  # was maximum baud rate?  Now telnet port
  property :maxrate, String, :length => 80
  property :location, String, :length => 80  
  #network and address seperated by ;
  property :network, Text
  #terminal types, seperated by ;
  property :terminal, String, :length => 255 
  property :megs, Integer
  property :msgs, Integer
  property :files, Integer
  property :nodes, Integer
  property :users, Integer  
  property :subs, Integer
  property :dirs, Integer
  property :xterns, Integer
  property :desc, Text
  
end
