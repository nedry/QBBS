require 'models/theme'

class User
  include DataMapper::Resource
    storage_names[:default] = 'users'
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
  property :create_date, DateTime
  property :laston, DateTime, :default => Time.now
  property :logons, Integer, :default => 0
  property :posted, Integer, :default => 0
  property :rsts_pw, String, :length => 40
  property :wg_pw, String, :length => 40
  property :rsts_acc, Integer 
  property :fullscreen, Boolean
  property :signature, Text
  property :fastlogon, Boolean
  property :theme_key, Integer
  property :screen_key, Integer

    has 1, :who, :child_key => [:number]
    has n, :pointers, :child_key => [:number]
    belongs_to :theme,  :child_key =>[:theme_key]
    belongs_to :theme,  :child_key =>[:screen_key]
   
    has n, :pages, :child_key => [:number]
    has 1, :who, :child_key => [:number] 
end
