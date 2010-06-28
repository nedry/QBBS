require 'models/who'

def create_who_table
  puts "-DB: Creating Who Table"
  @db.exec("CREATE TABLE who (number BigInt, lastactivity timestamp, \
           place varchar(40))")

end

def delete_who(uid)
  x = Who.first(:number => uid)
  x.destroy! if x
end

def add_who(number,lastactivity,place)
  Who.create(
    :number => number,
    :lastactivity => lastactivity,
    :place => place
  )
end

def update_who(uid,lastactivity,place)
  x = Who.first(:number => uid)
  x.update(
    :lastactivity => lastactivity,
    :place => place
  )
end

# TODO: move to datamapper
def fetch_who_list
  res = @db.exec("SELECT users.number, users.name, users.citystate, who.lastactivity, who.place FROM who LEFT OUTER JOIN users ON who.number=users.number ORDER BY users.name ") 
  result = result_as_array(res)
  return result
end

def who_exists(uid)
  Who.count(:number => uid) > 0
end

def who_list_check
  list = fetch_who_list
  list.each {|x|  delete_who(x[0]) if (Time.now- Time.parse(x[3])) / 60> WEB_IDLE_MAX }
end
