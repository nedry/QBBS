require 'models/user'
require 'models/pointer'
require 'models/page'

def u_total
  User.count
end

def p_total
   User.count(:conditions => {:profile_added => true})
end

def get_profile_index(uname)
   u = User.first(:conditions => ["upper(name) = ?", uname.upcase], :profile_added => true)
   result = nil
   fetch_profile_list.each_with_index {|a,i| result = i if a.number == u.number} if !u.nil?
   return result
end

def get_profile_start_alpha(alpha)
 User.all(:order =>[:name],:conditions =>{ :profile_added => true, :name.like => "%[#{alpha}-Z]%"})
 end

def fetch_profile_list
 User.all(:order =>[:name], :conditions => {:profile_added => true})
end

def find_RSTS_account
   act_rec = User.all( :rsts_acc.gt => 0,  :order => [ :rsts_acc.asc])
   if act_rec.length > 0 then
     next_acc = act_rec.last.rsts_acc + 1
   else
     next_acc = 1
   end
   next_acc = 0 if next_acc > RSTS_MAX
   next_acc
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

def update_user(r)
   r.save
 end

def fetch_user(record)
  User.first(:number => record)
end

def add_page(uid_from,to,message,system)
 uid =uid_from
 user = User.get(get_uid(to))
 page = user.pages.new(:message => message, :system => system, :from => uid)

 page.save
 puts page.errors.each {|e| puts e}
end

def delete_page(id)

page = Page.first(:id => id)
page.destroy!
end

def new_pages(user)

  user.pages.all.count   #I don't know why it has to be like this and not the other way..
end

def clear_pages(user)
   kill = user.pages.all
   kill.destroy! if kill
 end

 def clear_system_pages(user)
   kill = user.pages.all(:system => true)
   kill.destroy! if kill
 end

def get_all_pages(user)

  pages = user.pages.all(:order => [:left_at])
end

def add_pointer(record,area,access,p_value)
 uid = record.number
 user = User.get(uid)
 pointer = user.pointers.new(:area => area, :lastread => p_value, :access => access)
 pointer.save
end

def get_pointer(record,area)
  uid = record.number
  user = User.get(uid)
  pointer = user.pointers.first(:conditions => {:area => area})
end

def get_all_pointers(record)
  uid = record.number
  user = User.get(uid)
  pointers = user.pointers.all(:order => [:area])
end

def update_pointer(r)
  r.save
end

def add_user(name,ip,password,citystate,address,length,width,ansi, more, level, fullscreen,sex)
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
    :create_date => Time.now,
    :sex => sex
  )
end

def fetch_user_list
 User.all(:order =>[:name])
end

