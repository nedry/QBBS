# TODO: replace this with a rake task

require 'datamapper'
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

Theme.new(:number => 1,
:name => "QBBS",
:description => "Default Theme",
:main_prompt => MAIN_PROMPT,
:read_prompt => "%M;[@area@: @aname@]%C; @dir@ Read [%p] (1-@total@): %W;",

:text_directory => "text/").save!

Theme.new(:number => 2,
:name => "WBBS",
:description => "WBBS Theme",
:main_prompt => MAIN_PROMPT,
:read_prompt => "%M;Board @area@:%C; Read 1-@total@ [%p] (? for menu): %W;",
:nomainmenu => true,
:text_directory => "text/wbbs/").save!


YAML.load(IO.read('config/qbbscommands.yml')).each {|cmd|
  h = Command.new(cmd).save!

}


YAML.load(IO.read('config/wbbscommands.yml')).each {|cmd|
  h = Command.new(cmd).save!

}


happy = s.save
puts "errors:"
s.errors{|error| puts error}
puts happy


