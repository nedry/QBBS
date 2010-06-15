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
  b = Bulletin.first(:number => ind)
  b.destroy! if b
end

def update_bulletin(r)
  r.save
end

def fetch_bulletin(record)
  b = Bulletin.first(:number => record)
  if b
    b.name.gsub!(QUOTE,"'") if b.name
    b.path.gsub!(QUOTE,"'") if b.path
  end
  return b
end

def renumber_bulletins
  n = 1
  Bulletin.all(:order => :number).each do |b|
    b.update(:number => n)
    n = n + 1
  end
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
