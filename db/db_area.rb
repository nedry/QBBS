require 'models/area'
require 'models/message'

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
  if grp then
    areas = Area.all(:grp => grp,:order => [:number])
  else
    areas = Area.all(:order => [:number])
  end
  return areas
end

def find_qwk_area (number,grp)  # name for future use.
  Area.first(:netnum => number, :grp => grp)
end

def add_area(name, d_access,v_access,netnum,fido_net,group)
  number = a_total  #area's start with 0, so the total will be the next area
 
  netnum = -1 if netnum.nil?
  group = 1 if group.nil?

  Area.create(
    :number => number,
    :name => name,
    :d_access => d_access,
    :v_access => v_access,
    :modify_date => Time.now,
    :grp => group,
    :netnum => netnum,
    :fido_net => fido_net
  )
end


def fido_export_lst
    areas = Area.all(:fido_net.not => "", :fido_net.not => BADNETMAIL, :order => [:number])
end

def qwk_export_list(grp)
    areas = Area.all(:netnum.gt => - 1, :grp => grp, :order => [:number])
end
