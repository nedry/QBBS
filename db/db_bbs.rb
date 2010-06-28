def o_total
  Other.count
end

def create_other_table

  puts "-DB: Creating Other Table"
  @db.exec("CREATE TABLE other (name varchar(40), \
        locked boolean DEFAULT false, number int, \
           modify_date timestamp, address varchar(40),\
                  level int DEFAULT 0,  id serial PRIMARY KEY)")

end

def delete_other(ind)
  Other.delete_number(ind)
end

def update_other(r)
  r.save
end

def fetch_other(record)
  Other.first(:number => record)
end

def renumber_other
  Other.renumber!
end

def add_other(name, address)
  number = o_total + 1
  Other.create(
    :name => name,
    :number => number,
    :address => address,
    :modify_date => Time.now
  )
end
