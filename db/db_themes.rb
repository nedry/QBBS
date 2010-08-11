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
  
  user.theme_key = theme.theme_key
  user.save!
 
end

def get_user_theme(user)

  Theme.first(:theme_key => user.theme_key)
  
end

def add_command(command,theme,ulevel,menu_item)
  Command.new(:command => command, 
                          :theme_key => theme.theme_key, 
                          :ulevel => ulevel, 
                          :menu_item => menu_item)
end

def hash_commands (theme_key)
  puts "theme_key: #{theme_key}"
  command_list = Command.all(:theme_key => theme_key)
  command_hash = {}
  command_list.each {|cmd| command_hash[cmd.cmd] = cmd.menu_item}
  puts command_hash["areachange"]
  puts command_hash["who"]
  command_hash
end


def add_theme(name, description)
  number = t_total + 1
  Theme.create(
    :number => number,
    :name => name,
    :description => description,
    :text_directory => TEXT_DIRECTORY,
    :main_prompt => MAIN_PROMPT
  )
end

