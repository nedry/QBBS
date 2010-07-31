require 'models/bulletin'

def b_total
  Bulletin.count
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
