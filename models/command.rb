require 'models/theme'

class Command
  include DataMapper::Resource

  property :command_key, Serial
  property :theme_key, Integer
  property :menu_item, String, :length => 40, :index => true
  property :cmd, String, :length => 40
  property :ulevel, Integer, :default => 0
  belongs_to :theme, :child_key => [:theme_key]
  end
