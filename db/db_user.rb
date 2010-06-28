require 'models/user'

BEL = 7.chr

def u_total
  User.count
end

def create_user_table
  puts "-DB: Creating User Table"
  @db.exec("CREATE TABLE users (deleted boolean DEFAULT false, \
           locked boolean DEFAULT false, name varchar(40), \
           alias varchar(40), number bigserial PRIMARY KEY, \
           ip varchar(20), citystate varchar(40), address varchar(40),\
           password varchar(20), length int, modify_date date, \
           width int, ansi boolean, more boolean, level int, \
	area_access text, lastread text, create_date date,\
     laston date, logons int, posted int, rsts_pw varchar(40),\
     rsts_acc int, fullscreen boolean, zipread text,\
     signature text, fastlogon boolean DEFAULT false)")

     puts "-DB: Adding Default Users"	   

     add_user('SYSOP', '000.000.000.000','STUPID', 'Tempe, AZ','600 E. Solana Drive', 24, 80, true, true, 255,false)
     add_user('QWKREP', '000.000.000.000','123456', 'NO STREET', 'NO ADDRESS',24, 80, false, true, 255,false)
     add_user('FIDONET', '000.000.000.000','123456', 'NO STREET', 'NO ADDRESS',24, 80, false, true, 255,false)
end

def user_exists(uname)
  User.all(:conditions => ["upper(name) = ?", uname.upcase]).count > 0
end

def alias_exists(alais)
  User.all(:conditions => ["upper(alias) = ?", alais.upcase]).count > 0
end

# TODO: improve password handling
def check_password(uname,psswd)
  User.all(:conditions => ["upper(name) = ? and password = ?", uname.upcase, psswd]).count > 0
end

def get_uid(uname)
  u = User.first(:conditions => ["upper(name) = ?", uname.upcase])
  u ? u.number : nil
end

def update_user(r,uid)

  r.name.gsub!("'",BEL) if r.name != nil
  r.alais.gsub!("'",BEL) if r.alais != nil
  r.password.gsub!("'",BEL) if r.password != nil
  r.signature.gsub!("'",BEL) if r.signature != nil
  area_access = r.areaaccess.join('#') if r.areaaccess != nil 
  lastread = r.lastread.join('#') if r.lastread != nil
  zipread = r.zipread.join('#') if r.zipread != nil


  @db.exec("UPDATE users SET deleted = '#{r.deleted}', \
           locked = '#{r.locked}', name = '#{r.name}', \
           alias = '#{r.alais}', ip = '#{r.ip}',\
           citystate = '#{r.citystate}', address = '#{r.address}', \
           password = '#{r.password}',length = '#{r.length}',\
           modify_date = '#{r.modify_date}', width = '#{r.width}', \
           ansi = '#{r.ansi}', more = '#{r.more}',\
           level = '#{r.level}', area_access = '#{area_access}', \
           lastread = '#{lastread}', create_date = '#{r.create_date}',\
           laston = '#{r.laston}', logons = '#{r.logons}', \
           posted = '#{r.posted}', rsts_pw = '#{r.rsts_pw}',\
           rsts_acc = '#{r.rsts_acc}', fullscreen = '#{r.fullscreen}',\
           zipread = '#{zipread}', signature = '#{r.signature}', fastlogon = '#{r.fastlogon}'\
           WHERE number = #{uid}")
 end

def fetch_user(record)

  res = @db.exec("SELECT deleted ,locked, name, alias, ip,\
           citystate, address, password, length, modify_date,\
     width, ansi, more, level, area_access, lastread,\
     create_date, laston, logons, posted, rsts_pw,\
     rsts_acc, fullscreen, zipread, signature, fastlogon \
     FROM users WHERE number = #{record}") 

     temp = result_as_array(res).flatten

     t_deleted 	= db_true(temp[0])
     t_locked		= db_true(temp[1])
     t_name 		= temp[2]

     t_alias 		= temp[3]
     t_ip 		= temp[4]
     t_citystate 	= temp[5]
     t_address 	= temp[6]
     t_password 	= temp[7]
     t_length 		= temp[8].to_i
     t_modify_date	= temp[9]
     t_width 		= temp[10]
     t_ansi 		= db_true(temp[11])
     t_more 		= db_true(temp[12])
     t_level 		= temp[13].to_i
     t_area_access = temp[14].split('#') if !temp[14].nil? 

     if !temp[15].nil? then
       t_lastread = temp[15].split('#') 
       t_lastread.each_with_index {|x,i| t_lastread[i]=x.to_i}
     end

     t_createdate 	= temp[16]
     t_laston 		= temp[17]
     t_logons 		= temp[18].to_i
     t_posted 	= temp[19].to_i
     t_rsts_pw 	= temp[20]
     t_rsts_acc 	= temp[21].to_i
     t_fullscreen 	= db_true(temp[22])
     t_zipread 	= temp[23].split('#') if !temp[23].nil? 
     t_signature 	= temp[24]
      t_fastlogon 	= db_true(temp[25])

     t_name.gsub!(BEL,"'") if t_name != nil
     t_alias.gsub!(BEL,"'")if t_alias != nil
     t_citystate.gsub!(BEL,"'")if t_citystate != nil
     t_address.gsub!(BEL,"'")if t_address != nil
     t_password.gsub!(BEL,"'")if t_password != nil
     t_signature.gsub!(BEL,"'")if t_signature != nil

     result = DB_user.new(t_deleted, t_locked, t_name, t_alias,
                          t_ip, t_citystate, t_address, t_password,
                          t_length, t_modify_date, t_width, t_ansi,
                          t_more, t_level, t_area_access, t_lastread,
                          t_createdate, t_laston, t_logons, t_posted,
                          t_rsts_pw, t_rsts_acc, t_fullscreen, t_zipread,
                          t_signature,t_fastlogon)
     return result
end

def add_user(name,ip,password,citystate,address,length,width,ansi, more, level, fullscreen)
  User.create(
    :name => name,
    :ip => ip,
    :password => password,
    :citystate => citystate,
    :address => address,
    :length => length,
    :width => width,
    :ansi => ansi,
    :more => more,
    :level => level,
    :fullscreen => fullscreen,
    :create_date => Time.now
  )
end

def fetch_user_list
 res = @db.exec("SELECT  name, citystate, number FROM users ORDER BY name") 
 result = result_as_array(res)
return result
end
