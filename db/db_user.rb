require 'models/user'
require 'models/pointer'
require 'models/page'

def u_total
  User.count
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
end

def new_pages(user)
  
  user.pages.all.count   #I don't know why it has to be like this and not the other way..
end

def clear_pages(user)
   kill = user.pages.all
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
 User.all(:order =>[:name])
end
