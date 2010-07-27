require 'models/group'
require 'models/qwknet'

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
 
 qwkrep = group.qwknets.new(:name => name, :bbsid => bbsid, :qwkuser => qwkuser, :ftpaddress => ftpaddress, 
                                                :ftpaccount => ftpaccount, :ftppassword => ftppassword, :qwktag => qwktag,
                                                :qwkdir => qwkdir, :repdir => repdir, :qwkpacket => qwkpacket, 
                                                :reppacket => reppacket)
 e = qwkrep.save
 puts "Worked: #{e}"
 qwkrep.errors.each{|error| puts error}
end

def g_total
  Group.count
end