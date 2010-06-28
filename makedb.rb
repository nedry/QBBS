# TODO: replace this with a rake task

require 'datamapper'
require 'yaml'
require 'consts'


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

DataMapper.auto_migrate!

# create initial groups
%w(Local DoveNet FidoNet).each {|g|
  Group.new(:groupname => g).save!
}

# initial system
s = System.new(
  :lastqwkrep => '01/01/80',
  :qwkrepsuccess => false,
  :qwkrepwake => '01/01/80',
  :f_msgid => 9999999
)
s.save!

# initial users
YAML.load(IO.read('config/initusers.yml')).each {|u|
  User.new(u).save!
}
