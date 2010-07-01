require 'models/group'


def update_groups(number,name)
  g = Group.first(:number => number)
  g.update(:groupname => name)
end

def fetch_groups
  Group.all(:order => :number)
end
