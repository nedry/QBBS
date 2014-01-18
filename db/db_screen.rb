require 'models/screensaver'

def s_total
  Screensaver.count
end


def delete_screen(ind)
  Screensaver.delete_number(ind)
end

def update_screen(r)
  r.save
end

def fetch_screen(record)
  Screensaver.first(:number => record)
end

def renumber_screens
 Screensaver.renumber!
end

def add_screen(name, path)
  number = s_total + 1
  Screensaver.create(
    :number => number,
    :name => name,
    :path => path,
    :modify_date => Time.now
  )
end

def add_screen_to_user(user,screen)

  user.screen_key = screen.screen_key
  user.save!

end

def clear_screen(user)

  user.screen_key = nil
  user.save!

end

def get_user_screen(user)

  Screensaver.first(:screen_key => user.screen_key)

end