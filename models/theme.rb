require 'models/command'
require 'models/user'
class Theme
  include DataMapper::Resource
  property :theme_key, Serial
  property :number, Integer
  property :name, String, :length => 40
  property :delete, Boolean, :default => false
  property :locked, Boolean, :default => false
  property :modify_date, DateTime, :default => Time.now
  property :description, String, :length => 80
  property :main_prompt, String, :length => 80
  property :read_prompt, String, :length => 80
  property :email_prompt, String, :length => 80
  property :text_directory, String, :length => 80
  has n, :commands, :child_key => [:theme_key]
  belongs_to :user, :child_key =>[:theme_key]
end
