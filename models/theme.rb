require 'models/command'
require 'models/user'
class Theme
  include DataMapper::Resource
  property :theme_key, Serial
  property :number, Integer
  property :name, String, :length => 40
  property :delete, Boolean, :default => false
  property :locked, Boolean, :default => false
  property :nomainmenu, Boolean, :default => false
  property :areachangeonmain, Boolean, :default => true
  property :modify_date, DateTime, :default => Time.now
  property :description, String, :length => 200
  property :user_prompt, String, :length => 200
  property :door_prompt, String, :length => 200
  property :bull_prompt, String, :length => 200
  property :no_mail_prompt, String, :length => 200
  property :yes_mail_prompt, String, :length => 200 
  property :yes_mail_readit, String, :length => 200
  property :main_prompt, String, :length => 200
  property :read_prompt, String, :length => 200
  property :email_prompt, String, :length => 200
  property :logout_prompt, String, :length => 200
  property :text_directory, String, :length => 80
  has n, :commands, :child_key => [:theme_key]
   has n, :users, :child_key => [:theme_key]
   end
