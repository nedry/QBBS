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
#(name, d_access,v_access,netnum,fido_net,group)
add_area("Email","I","I",nil,nil,1)
add_area("General Discussions","W","W",nil,nil,1)
add_area("The APC Net","W","W",nil,nil,1)

#Synchronet

add_area("General","W","W",2001,nil,2)
add_area("Adverstisements","W","W",2002,nil,2)
add_area("Entertainment","W","W",2003,nil,2)
add_area("Debate","W","W",2004,nil,2)
add_area("Hardware/Software Help","W","W",2005,nil,2)
add_area("Programming","W","W",2006,nil,2)
add_area("Unix Discussion","W","W",2009,nil,2)
add_area("Ham Radio","W","W",2015,nil,2)
add_area("Internet","W","W",2016,nil,2)
add_area("Pro-Audio","W","W",2017,nil,2)
add_area("Firearms","W","W",2008,nil,2)
add_area("Sports Discussion","W","W",2019,nil,2)
add_area("Religious Nuts","W","W",2020,nil,2)
add_area("Synchronet Announcements","W","W",2030,nil,2)
add_area("Hobbies","W","W",2021,nil,2)
add_area("Synchronet Discussion","W","W",2007,nil,2)
add_area("Sysops Only","I","I",2008,nil,2)
add_area("Synchronet Prog. (Baja)","W","W",2011,nil,2)
add_area("Synchronet Prog. (Javascript)","W","W",2012,nil,2)
add_area("Synchronet Prog. (c/c++/cvs)","W","W",2010,nil,2)

#FidoNet

add_area("Sysop712","I","I",nil,"SYSOP712",3)
add_area("Netmail","I","I",nil,"NETMAIL",3)
add_area("BadNetMail","I","I",nil,"BADNETMAIL",3)
add_area("Weather","W","W",nil,"WEATHER",3)
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
