require 'models/actions'

def ac_total
  Actions.count
end

def delete_action(ind)
  Actions.delete_number(ind)
end

def update_action(r)
  r.save
end

def fetch_actionr(record)
  Actions.first(:number => record)
end

def renumber_action
  Actions.renumber!
end

def add_action(name, action, local_action, me_action, directed)
  number = ac_total + 1
  Actions.create(
    :name => name,
    :number => number,
    :action => action,
    :local_action => local_action,
    :directed => directed,
    :me_action => me_action,
    :modify_date => Time.now
  )
end
