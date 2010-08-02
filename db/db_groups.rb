require 'models/group'
require 'models/qwknet'
require 'models/qwkroute'

def update_groups(number,name)
  g = Group.first(:number => number)
  g.update(:groupname => name)
end

def fetch_groups
  Group.all(:order => :grp)
end

def fetch_group(number)
  Group.first(:number => number)
end

def fetch_group_grp(number)
  Group.first(:grp => number)
end

def update_group(g)
  g.save
end

def add_group(name)
  number = g_total 
  Group.create(
    :groupname => name,
    :number => number
  )
end


def get_qwk_dest(route)
  
 dest = nil
  
if !route.nil?  
 routes = route.split ("/")
 dest = routes.pop
 route = routes.join("/")
end
 return [dest,route]
end

def find_qwk_route(dest)
  area = nil
  qwkroute = Qwkroute.first(:conditions => ["upper(dest) = ?", dest.upcase])
  if !qwkroute.nil?
   area = fetch_group_grp(get_qwknet(qwkroute).grp).number
 end
 return area
 end


def get_qwkroute(qwknet,dest)
  qwkroute = qwknet.qwkroutes.first(:dest => dest)
end

def save_qwkroute(qwknet,dest,route)
   qwkroute = qwknet.qwkroutes.new(:dest => dest, :route => route)
   qwkroute.save
 end
 
 def update_qwkroute(qwkroute)
   qwkroute.save
 end
 
 def remove_qwkroute(qwknet,dest)
   qwkroute = qwknet.qwkroutes.first(:dest => dest)
   qwkroute.destroy!
 end
 
 def qwkroute_scavenge(qwknet)
   current_date = Time.now
   scavengetime = Time.now - (DAY_SEC * ROUTE_SCAVENGE)
   qwkroute = qwknet.qwkroutes.all(:modified.lte => scavengetime)
   qwkroute.destroy!
 end
    
def get_qwknet(group)
  qwknet = group.qwknets.first
end

def remove_qwknet(group)
  qwknet = group.qwknets.first
  qwknet.destroy!
end

def update_qwknet(qwknet)
  qwknet.save
end

def add_qwknet(group,name,bbsid,qwkuser,ftpaddress,ftpaccount,ftppassword)
  
 qwktag = convert_to_utf8(D_QWKTAG)
 qwkdir = D_QWKDIR
 repdir = D_REPDIR
 bbsid.upcase!
 qwkpacket = "#{bbsid}.#{D_QWKEXT}"
 reppacket = "#{bbsid}.#{D_REPEXT}"
 repdata = "#{bbsid}.#{D_REPDATA}"
 
 qwkrep = group.qwknets.new(:name => name, :bbsid => bbsid, :qwkuser => qwkuser, :ftpaddress => ftpaddress, 
                                                :ftpaccount => ftpaccount, :ftppassword => ftppassword, :qwktag => qwktag,
                                                :qwkdir => qwkdir, :repdir => repdir, :qwkpacket => qwkpacket, 
                                                :reppacket => reppacket, :repdata => repdata)
 e = qwkrep.save
 puts "Worked: #{e}"
 qwkrep.errors.each{|error| puts error}
end

def g_total
  Group.count
end