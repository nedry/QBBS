# TODO: replace this with a rake task
$LOAD_PATH << "."
require 'data_mapper'
require "dm-validations"
require 'yaml'
require 'consts'
require 'db/db_area'
require 'db/db_groups'
require 'db/db_message'



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
DataMapper.auto_migrate!
# create initial groups

Group.new(:groupname => 'Local', :number => 0 ).save!
Group.new(:groupname => 'Dove.net', :number => 1 ).save!
#Group.new(:groupname => 'Fidonet', :number => 2 ).save!
#Group.new(:groupname => 'Paranormal Net', :number =>  3 ).save!

Group.new(:groupname => 'Usenet', :number =>  1 ).save!

Subsys.new(:subsystem => 1, :name => 'SCHEDULE').save!
Subsys.new(:subsystem => 2, :name => 'FIDO').save!
Subsys.new(:subsystem => 3, :name => 'EXPORT').save!
Subsys.new(:subsystem => 4, :name => 'IMPORT').save!
Subsys.new(:subsystem => 5, :name => 'USER').save!
Subsys.new(:subsystem => 6, :name => 'CONNECT').save!
Subsys.new(:subsystem => 7, :name => 'SECURITY').save!
Subsys.new(:subsystem => 8, :name => 'ERROR').save!
Subsys.new(:subsystem => 9, :name => 'MESSAGE').save!


Theme.new(:number => 1,
                   :name => "QBBS", 
                   :description => "Default Theme", 
                   :main_prompt => MAIN_PROMPT, 
		   :read_prompt => "%M;[@area@: @aname@]%C; @dir@ Read [%p] (1-@total@): %W;",
		   :logout_prompt => "%W;Log off now (%Y;Y%W;,%R;n%W;): ",
		   :door_prompt => "\r\n%G;Game #[1-@dtotal@] ? #{RET} %G;to quit: %W;",
		   :bull_prompt => "\r\n%G;Bulletins #[1-@btotal@] ? #{RET} %G;to quit: %W;",
		   :user_prompt => "%W;Change Which User Setting ? #{RET} to quit: ",
		   :no_mail_prompt => "%W;Scanning for New Email... none.",
		   :yes_mail_prompt => "%W;Scanning for New Email... @new@ message(s).\r\n",
		   :yes_mail_readit => "\r\nRead them now #{YESNO}",
		   :pause_prompt => "%W;Press (%G;N/Nonstop %R;Q/Quit%W;) #{RET} ",
		   :zipread_prompt => "%G;Would you like to perform a new message scan %W;(%G;ZIPread%W;)? #{YESNO} ",
		   :profileedit_prompt => "%C;Select a letter from the above list: %W;",
		   :profile_prompt => "%C;Select an option (G,D,Y,L,X, or ?): %W;",
		   :proflle_lookup => "%C;Enter User-ID to look-up, B to browse or X to exit: %W;",
		   :profile_full_prompt => "%C;Where in the alphabet (A-Z) do you wish to begin your directory listing? %W;",
		   :profile_comlete_entry => "%G;By the way, you haven't filled out your User Profile yet...\r\nJust select %C;U%G; from the main menu to enter the User Profile System!" ,
		   :profile_date_format => "%A the %-d%Z of %B, %Y at %I:%M%p",
		   :zipreadonlogon => true,
		   :nomainmenu => false,
		   :profile_flat_menu => true,
		   :text_directory => "text/").save!
                   
Theme.new(:number => 2, 
                   :name => "WBBS", 
                   :description => "WBBS Theme", 
                   :main_prompt => MAIN_PROMPT,
		   :read_prompt => "%M;Board @area@:%C; Read 1-@total@ [%p] (? for menu): %W;",
		   :logout_prompt => "%W;Log off now (%Y;Y%W;,%R;n%W;): ",
		   :door_prompt => "\r\n%G;Game #[1-@dtotal@] ? #{RET} %G;to quit: %W;",
		   :bull_prompt => "\r\n%G;Bulletins #[1-@btotal@] ? #{RET} %G;to quit: %W;",
		   :user_prompt => "%W;Change Which User Setting ? #{RET} to quit: ",
		   :no_mail_prompt => "%W;Scanning for New Email... none.",
		   :yes_mail_prompt => "%W;Scanning for New Email... @new@ message(s).\r\n",
		   :yes_mail_readit => "\r\nRead them now #{YESNO}",
		   :pause_prompt => "%W;Press (%G;N/Nonstop %R;Q/Quit%W;) #{RET} ",
		   :zipread_prompt => "%G;Would you like to perform a new message scan %W;(%G;ZIPread%W;)? #{YESNO} ",
		   :zipreadonlogon => true,
                   :nomainmenu => true,
		   :profile_flat_menu => true,
		   :profileedit_prompt => "%C;Select a letter from the above list: %W;",
		   :profile_prompt => "%C;Select an option (G,D,Y,L,X, or ?): %W;",
		   :proflle_lookup => "%C;Enter User-ID to look-up, B to browse or X to exit: %W;",
		   :profile_full_prompt => "%C;Where in the alphabet (A-Z) do you wish to begin your directory listing? %W;",
		   :profile_comlete_entry => "%G;By the way, you haven't filled out your User Profile yet...\r\nJust select %C;U%G; from the main menu to enter the User Profile System!",
		   :profile_date_format => "%D  %T",
		   :text_directory => "text/wbbs/").save!
		   
Theme.new(:number => 3, 
                   :name => "MajorBBS", 
                   :description => "The Rock Garden Theme", 
                   :main_prompt => "\r\n%G;Main System Menu %w;(%G;MAIN%w;)\r\n%w;Select (%C;T,I,F,E,A,P,G,R,? %W;for help, or %C;X%W; to exit%w;): %W;",
                   :read_prompt => "%M;Board @area@:%C; Read 1-@total@ [%p] (? for menu): %W;",
		   :logout_prompt => "%R;You are about to terminate this connection!\r\n\r\n%C;Are you sure (Y/N)?",
		   :door_prompt => "\r\n%G;GAMES %w;(%G;GAMES%w;)\r\n%w;Select (%C;@dlist@,%W; ? for help, or %C;X%W; to exit%w;): %W;",
		   :bull_prompt => "\r\n%G;Information Center %w;(%G;INFO%w;)\r\n%w;Select (%C;@blist@,%W; ? for help, or %C;X%W; to exit%w;): %W;",
		   :user_prompt => "\r\n%G;User Settings %w;(%G;USERS%w;)\r\n%w;Select (%C;C,E,F,G,L,M,W,P,SI,Z,T,%W; ? for help, or %C;X%W; to exit%w;): %W;",
		   :no_mail_prompt => "",
		   :yes_mail_prompt => "%Y;There is %W;new%Y; mail in your mailbox!",
		   :yes_mail_readit => "\r\n\r\n%C;Do you want to see it now (Y/N)?",
		   :pause_prompt => "%w;[N]onstop, [Q]uit, or [C]ontinue? ",
		   :zipread_prompt => "%C;Would you like to perform a new message scan %W;(%G;ZIPread%W;)? (Y/N) ",
		   :profileedit_prompt => "%C;Select a letter from the above list: %W;",
		   :profile_prompt => "%C;Select an option (G,D,Y,L,X, or ?): %W;",
		   :proflle_lookup => "%C;Enter User-ID to look-up, B to browse or X to exit: %W;",
		   :profile_full_prompt => "%C;Where in the alphabet (A-Z) do you wish to begin your directory listing? %W;",
		   :profile_comlete_entry => "%G;By the way, you haven't filled out your Registry entry yet...\r\nJust select %C;R%G; from the TOP menu to enter the Registry!",
		   :profile_date_format => "%A, %B %-d, %Y   %l:%M%P",
		   :message_prompt => "%C;Select a letter from this list, or X to exit: ",
		   :zipreadonlogon => false,
		   :nomainmenu => false,
		   :profile_flat_menu => false,
		   :text_directory => "text/mbbs/").save!


t = 

  Screensaver.create(
    :number => 1,
    :name => "Fish Tank",
    :path => "perl external/aquarium",
    :modify_date => Time.now
  ).save!

  Screensaver.create(
    :number => 2,
    :name => "Local Weather",
    :path => "perl external/weatherspect",
    :modify_date => Time.now
  ).save!
  
YAML.load(IO.read('config/qbbscommands.yml')).each {|cmd|
  h = Command.new(cmd).save!

}


YAML.load(IO.read('config/wbbscommands.yml')).each {|cmd|
  h = Command.new(cmd).save!

}

YAML.load(IO.read('config/mbbscommands.yml')).each {|cmd|
  h = Command.new(cmd).save!

}

# initial users
YAML.load(IO.read('config/initusers.yml')).each {|u|
  h = User.new(u).save!

}

# initial area
#(name, d_access,v_access,netnum,fido_net,group)
add_area("Email","I","I",nil,nil,nil,1)
add_area("General Discussions","W","W",nil,nil,nil,1)
add_area("The APC Net","W","W",nil,nil,nil,1)

#Synchronet

add_area("General","W","W",2001,nil,nil,2)
#add_area("Adverstisements","W","W",2002,nil,nil,2)
#add_area("Entertainment","W","W",2003,nil,nil,2)
#add_area("Debate","W","W",2004,nil,nil,2)
#add_area("Hardware/Software Help","W","W",2005,nil,nil,2)
#add_area("Programming","W","W",2006,nil,nil,2)
#add_area("Unix Discussion","W","W",2009,nil,nil,2)
#add_area("Ham Radio","W","W",2015,nil,nil,2)
#add_area("Internet","W","W",2016,nil,nil,2)
#add_area("Pro-Audio","W","W",2017,nil,nil,2)
#add_area("Firearms","W","W",2008,nil,nil,2)
#add_area("Sports Discussion","W","W",2019,nil,nil,2)
#add_area("Religious Nuts","W","W",2020,nil,nil,2)
#add_area("Synchronet Announcements","W","W",2030,nil,nil,2)
#add_area("Hobbies","W","W",2021,nil,2)
#add_area("Synchronet Discussion","W","W",2007,nil,nil,2)
#add_area("Sysops Only","I","I",2008,nil,nil,2)
add_area("dove data","W","W",2013,nil,nil,2)
#add_area("Synchronet Prog. (Javascript)","W","W",2012,nil,nil,2)
#add_area("Synchronet Prog. (c/c++/cvs)","W","W",2010,nil,nil,2)

#add_area("DoveQWKMail","I","I",0,nil,nil,2)

#FidoNet
#add_area("Sysop712","I","I",nil,"SYSOP712",nil,3)
#add_area("Netmail","I","I",nil,"NETMAIL",nil,3)
#add_area("BadNetMail","I","I",nil,"BADNETMAIL",nil,3)
#add_area("Weather","W","W",nil,"WEATHER",nil,3)

#add_area("ParaQWKMail","I","I",0,nil,nil,4)

#add_area("UFO Reports","W","W",5001,nil,nil,4)
#add_area("UFO Discussion","W","W",5002,nil,nil,4)
#add_area("Origins and Ancients","W","W",5003,nil,nil,4)
#add_area("Mars","W","W",5004,nil,nil,4)
#add_area("NASA - The Moon and Beyond","W","W",5005,nil,nil,4)
#add_area("Out of Body","W","W",5006,nil,nil,4)
#add_area("Past Lives and Deja Vu","W","W",5007,nil,nil,4)
#add_area("Hauntings, Ghosts and Spirits","W","W",5008,nil,nil,4)
#add_area("Psychic Healing","W","W",5009,nil,nil,4)
#add_area("Angles and Miracles","W","W",5010,nil,nil,4)
#add_area("Paranormal Net Sysops","I","I",5011,nil,nil,4)
#add_area("Abductions","W","W",5012,nil,nil,4)
#add_area("Crop Circles","W","W",5013,nil,nil,4)
#add_area("Psychic","W","W",5014,nil,nil,4)
#add_area("Pagan/Wiccan","W","W",5015,nil,nil,4)
#add_area("Super Sciences and Events","W","W",5016,nil,nil,4)
#add_area("X-Files TV Show","W","W",5017,nil,nil,4)
#add_area("Conspiracies","W","W",5018,nil,nil,4)
#add_area("The Quickening","W","W",5019,nil,nil,4)


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



