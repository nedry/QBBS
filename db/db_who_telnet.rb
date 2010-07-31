require 'models/who_t'

def who_delete_t(name)
  x = Who_t.first(:name => name)
  x.destroy! if x
end

def delete_irc_t
  x=Who_t.all(:irc => true)
  x.destroy!
end

def clear_who_t
  x=Who_t.all
  x.destroy!
end

def add_who_t(irc,node,location,where,name)
  Who_t.create(
    :irc => irc,
    :node => node,
    :location => location,
    :where => where,
    :name => name)
end

def update_who_t(name,wh)

  who = Who_t.first(:name => name)
  who.name = name
  who.wh = wh
  who.save
end

def fetch_who_t_list
  who = Who_t.all(:order => [:name])
end

def who_t_exists(name)
 Who_t.all(:name => uid).count >0 
end
