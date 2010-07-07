require 'models/area'

def a_total
  Area.count
end

def update_group(r)
  r.save
end

def update_area(r)
  r.save
end

def fetch_area(record)
  Area.first(:number => record)
end


def add_area(group,area)
 group = Group.get(group)
 area = group.areas.new(:grp => group)
 area.save
end

def fetch_area_list(grp)
 
 if !grp.nil? then
  areas = Area.all(:grp => grp,:order => [:number])
else
   areas = Area.all(:order => [:number])
end
return areas
end

def find_qwk_area (number,name)  # name for future use.
  Area.first(:netnum => number)
end

def add_area(name, d_access,v_access)
  number = a_total  #area's start with 0, so the total will be the next area

  Area.create(
    :number => number,
    :name => name,
    :d_access => d_access,
    :v_access => v_access,
    :modify_date => Time.now
  )
end
