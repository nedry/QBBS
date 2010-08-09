require 'models/theme'
require 'models/command'
require 'models/user'
require 'db/db_user'

def t_total
  Theme.count
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
  user.theme = theme
  user.save
end

def get_user_theme(user)
  user.theme
end

def add_theme(name, description)
  number = t_total + 1
  Theme.create(
    :number => number,
    :name => name,
    :description => description
  )
end

