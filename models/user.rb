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
  
  property :sex,String, :length => 5
  property :real_name, String, :length =>40
  property :aliases, String, :length =>40
  property :age,Integer
  property :city_state, String, :length =>40
  property :real_name, String, :length =>40
  property :voice_phone, String, :length =>40
  property :p_description, String, :length =>40
  property :url, String, :length =>40
  property :fav_movie, String, :length =>40
  property :fav_music, String, :length =>40
  property :fav_food, String, :length =>40
  property :fav_sport, String, :length =>40
  property :fav_tv, String, :length =>40
  property :insturments, String, :length =>40
  property :hobbies, String, :length =>40
  property :gen_info1, String, :length =>80
  property :gen_info2, String, :length =>80
  property :summary, String, :length =>40
  property :profile_added, Boolean, :default => false
  property :birthdate,Date
  property :fastlogon, Boolean
	property :page_on, Boolean, :default => true
  property :theme_key, Integer
  property :screen_key, Integer

    has 1, :who, :child_key => [:number]
    has n, :pointers, :child_key => [:number]
    belongs_to :theme,  :child_key =>[:theme_key]
    belongs_to :theme,  :child_key =>[:screen_key]
   
    has n, :pages, :child_key => [:number]
    has 1, :who, :child_key => [:number] 
end
