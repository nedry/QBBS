require 'models/bbslist'

def bbs_total
  Bbslist.count
end

def delete_bbs(ind)
  Bbslist.delete_number(ind)
end

def update_bbs(r)
  r.save
end

def fetch_bbs(record)
  Bbslist.first(:number => record)
end

def renumber_bbs
  Bbslist.renumber!
end

def exists_bbs(bname)
 if !bname.nil?
    Bbslist.all(:conditions => ["upper(name) = ?", bname.upcase]).count > 0
 end
end

def delete_bbs(bname)
    bbs = Bbslist.all(:conditions => ["upper(name) = ?", bname.upcase])
    bbs.destroy!
end

def add_bbslist(name,born_date,software,sysop,email,website, number, minrate,
			    maxrate,location,network,terminal,megs,msgs,files,
			    nodes, users, subs, dirs,xterns,desc,imported)

  Bbslist.create(
    :name => name,
    :born_date => born_date,
    :software => software,
    :sysop => sysop,
    :email => email,
    :website => website,
    :number => number,
    :maxrate => maxrate,
    :location => location,
    :network => network,
    :terminal => terminal,
    :megs => megs,
    :msgs => msgs,
    :files => files,
    :nodes => nodes,
    :users => users,
    :subs => subs,
    :dirs => dirs,
    :xterns => xterns,
    :desc => desc,
    :imported => imported,
    :modify_date => Time.now
  )
end
