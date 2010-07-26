require 'models/other'

def o_total
  Other.count
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
