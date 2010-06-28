require 'models/door'

def d_total
  Door.count
end

def create_door_table
  puts "-DB: Creating Doors Table"
  @db.exec("CREATE TABLE doors (name varchar(40), \
        locked boolean DEFAULT false, number int, \
           modify_date timestamp, d_path varchar(40),\
            d_type varchar(10), path varchar(40),\
      level int DEFAULT 0, droptype varchar(10) DEFAULT 'RBBS', id serial PRIMARY KEY)")
end

def delete_door(ind)
  Door.delete_number(ind)
end

def update_door(r)
  r.save
end

def fetch_door(record)
  Door.first(:number => record)
end

def renumber_doors
  Door.renumber!
end

def add_door(name, path)
  number = d_total + 1
  Door.create(
    :number => number,
    :name => name,
    :path => path,
    :date => Time.now
  )
end
