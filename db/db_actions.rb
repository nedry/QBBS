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

def add_action(name, action, local_action, me_action, directed)
  number = ac_total + 1
  Action.create(
    :name => name,
    :number => number,
    :action => action,
    :local_action => local_action,
    :directed => directed,
    :me_action => me_action,
    :modify_date => Time.now
  )
end
