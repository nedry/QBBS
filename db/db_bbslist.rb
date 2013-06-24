require 'models/bbslist'

def bbs_total
  Bbslist.count
end


def update_bbs(r)
  r.save
end

def absolute_bbs(ind)
  ind = 0 if ind.nil?
  lazy_list = Bbslist.all(:order => [ :name ])
  result = 0
  result = lazy_list[ind-1].id if !lazy_list[ind-1].nil?
end

def fetch_bbs(record)
  Bbslist.first(:id => record)
end

def delete_all_bbs
  bbs= Bbslist.all
  bbs.destroy!
end

def delete_all_bbs_old
  before_date = Date.today - 30
  bbs= Bbslist.all(:modify_date.lte => before_date, :locked => false)
  bbs.destroy!
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
