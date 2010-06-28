require 'models/bulletin'

def b_total
  Bulletin.count
end

# TODO: we should not be creating tables in our code at all
# Should be done with a separate setup script
def create_bulletin_table
  puts "-DB: Creating Bulletins Table"
  @db.exec("CREATE TABLE bulletins (name varchar(40), \
        locked boolean DEFAULT false, number int, \
           modify_date timestamp, b_path varchar(40),\
            id serial PRIMARY KEY)")
end

def delete_bulletin(ind)
  Bulletin.delete_number(ind)
end

def update_bulletin(r)
  r.save
end

def fetch_bulletin(record)
  Bulletin.first(:number => record)
end

def renumber_bulletins
  Bulletin.renumber!
end

def add_bulletin(name, path)
  n = b_total + 1
  b = Bulletin.create(
    :name => name,
    :path => path,
    :number => n,
    :modify_date => Time.now
  )
end
