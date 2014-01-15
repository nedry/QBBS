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

def fetch_bbs_all
  Bbslist.all(:order => [ :name ])
end

def bbs_import(area,first)
  messages = Message.all(:absolute.gte => first, :number => area)
end

def bbs_empty

  result = true
  temp = Bbslist.count
  result = false if temp > 0 
  return result
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

def delete_bbs_pointer(pointer)
   abs = absolute_bbs(pointer)
    bbs = Bbslist.all(:id => abs)
    bbs.destroy!
end

def add_bbslist(name,born_date,software,sysop,email,website, number, minrate,
			    maxrate,location,network,terminal,megs,msgs,files,
			    nodes, users, subs, dirs,xterns,desc,imported)
			    
  megs = 32767 if megs.to_i > 32767  # this should be a bigint and why doesn't dm-validtions catch this?

  newbbs = Bbslist.new(
    :user => "SYSTEM",
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
    worked = newbbs.save
  if !worked then
   newbbs.errors.each{|x| @debuglog.push("-ERROR: #{x}")}
   sleep(1)
  end
end
