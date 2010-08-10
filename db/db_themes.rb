require 'models/theme'
require 'models/command'
require 'models/user'
require 'db/db_user'
require 'consts'

def t_total
  Theme.count
end

def delete_theme(r)
   r.destroy!
 end
 
def update_theme(r)
  r.save
end

def fetch_theme(record)
  Theme.first(:number => record)
end

def renumber_themes
  Theme.renumber!
end

def add_theme_to_user(user,theme)
  #user.themes = theme
  if  !Theme.first(user).nil? then
    puts user.theme.all.count
    puts "found a theme! "#{Theme.get(user).count}"
    Theme.first(theme).users.(:number => user.number)
    x = Theme.first(theme).users(:number => user.number).clear
    x.save
  end
  puts "theme.theme_key #{theme.theme_key}"
  happy = Theme.first(:theme_key => theme.theme_key).users << user
  happy.save!
 # Theme.errors.each{|x| puts x}
  
end

def get_user_theme(user)
  Theme.first(user)
end

def add_theme(name, description)
  number = t_total + 1
  Theme.create(
    :number => number,
    :name => name,
    :description => description,
    :main_prompt => MAIN_PROMPT
  )
end

