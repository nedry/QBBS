require 'models/door'

def d_total
  Door.count
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
    :modify_date => Time.now
  )
end
