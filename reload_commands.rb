# TODO: replace this with a rake task
$LOAD_PATH << "."
require 'data_mapper'
require "dm-validations"
require 'yaml'
require 'consts'
require 'db/db_area'
require 'db/db_groups'
require 'db/db_message'
require 'db/db_themes'


Dir['models/*'].each {|i| require i}

c = YAML.load(IO.read('config/db.yml'))
if c['connect_string']
  cstr = c['connect_string']
else
  if c['adapter'] == 'sqlite3'
    cstr = "#{c['adapter']}://#{Dir.pwd}/#{c['db']}"
  else
    cstr = "#{c['adapter']}://#{c['user']}:#{c['password']}@#{c['host']}/#{c['db']}"
  end
end

# use consts.rb for now
cstr = "postgres://#{DATAIP}/#{DATABASE}"

puts "connecting to #{cstr}"

DataMapper.setup(:default, cstr)
DataMapper::Logger.new('log/db', :debug)
DataObjects::Postgres.logger = DataObjects::Logger.new(STDOUT,:debug) 
DataMapper.finalize
clear_commands

YAML.load(IO.read('config/qbbscommands.yml')).each {|cmd|
  h = Command.new(cmd).save!

}


YAML.load(IO.read('config/wbbscommands.yml')).each {|cmd|
  h = Command.new(cmd).save!

}

YAML.load(IO.read('config/mbbscommands.yml')).each {|cmd|
  h = Command.new(cmd).save!

}



