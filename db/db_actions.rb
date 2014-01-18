require 'models/other'

def ac_total
  Action.count
end

def delete_action(ind)
  Action.delete_number(ind)
end

def update_action(r)
  r.save
end

def fetch_actionr(record)
  Action.first(:number => record)
end

def renumber_action
  Action.renumber!
end

def add_action(name, address)
  number = ac_total + 1
  Action.create(
    :name => name,
    :number => number,
    :action => action,
    :modify_date => Time.now
  )
end
