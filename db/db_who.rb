require 'models/who'

def delete_who(uid)
  x = Who.first(:number => uid)
  x.destroy! if x
end

def w_total
  Who.count
end

def add_who(number,lastactivity,place,access,sex)
  Who.create(
    :number => number,
    :lastactivity => lastactivity,
    :place => place,
    :access => access,
    :sex => sex
  )
end

def update_who(uid,lastactivity,place)
  x = Who.first(:number => uid)
  x.update(
    :lastactivity => lastactivity,
    :place => place
  )
end

def fetch_who_list
  result = Who.all.sort_by { |x| x.user.name }
  return result
end

def who_exists(uid)
  Who.all(:number => uid).count >0  #I don't know why it has to be like this and not the other way..
end

def who_list_check
  list = fetch_who_list
  list.each {|x|  delete_who(x.number) if (Time.now- Time.parse(x.lastactivity.to_s)) / 60> WEB_IDLE_MAX }
end
