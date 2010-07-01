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

def fetch_area_list(num)

  a_list = []

  out = nil
  out = " and areas.grp = '#{num}'" if !num.nil?

  res = @db.exec("SELECT areas.name,areas.delete,areas.number,groups.groupname,areas.tbl \
           FROM areas,groups WHERE areas.grp = groups.number #{out} ORDER BY areas.grp,areas.number")

           temp = result_as_array(res)

           for i in 0..temp.length - 1 do
             t_name		= temp[i][0]
             t_delete	= db_true(temp[i][1])
             t_number	= temp[i][2].to_i
             t_group		= temp[i][3]
             t_tbl		= temp[i][4]
             a_list << DB_area_list.new(t_name,t_delete,t_number,t_group,t_tbl)
           end

           return a_list

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
