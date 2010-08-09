require 'models/theme'

class Command
  include DataMapper::Resource

  property :command_key, Serial
  property :menu_item, String, :length => 40, :index => true
  property :command, String, :length => 40
  belongs_to :theme, :child_key => [:area_key]
  end
