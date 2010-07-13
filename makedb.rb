# TODO: replace this with a rake task

require 'datamapper'
require "dm-validations"
require 'yaml'
require 'consts'
require 'db/db_area'


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

DataMapper.auto_migrate!

# create initial groups
%w(Local DoveNet FidoNet).each {|g|
  Group.new(:groupname => g).save!
}


Subsys.new(:subsystem => 2, :name => 'FIDO').save!
Subsys.new(:subsystem => 3, :name => 'EXPORT').save!
Subsys.new(:subsystem => 4, :name => 'IMPORT').save!
Subsys.new(:subsystem => 5, :name => 'USER').save!
Subsys.new(:subsystem => 6, :name => 'CONNECT').save!
Subsys.new(:subsystem => 7, :name => 'SECURITY').save!
Subsys.new(:subsystem => 8, :name => 'ERROR').save!
Subsys.new(:subsystem => 9, :name => 'MESSAGE').save!
Subsys.new(:subsystem => 1, :name => 'SCHEDULE').save!


t = 


# initial users
YAML.load(IO.read('config/initusers.yml')).each {|u|
  h = User.new(u).save!

}

# initial area
add_area("Email","I","I")
add_area("General Discussions","W","W")
add_area("The APC Net","W","W")

# initial system
s = System.new(
  :lastqwkrep => Time.now,
  :qwkrepsuccess => false,
  :qwkrepwake => Time.now,
  :f_msgid => 9999999
)
happy = s.save
puts "errors:"
s.errors{|error| puts error}
puts happy
