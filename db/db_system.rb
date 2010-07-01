

def update_system(r)


  @db.exec("UPDATE system SET lastqwkrep = '#{r.lastqwkrep}', \
           qwkrepsuccess = '#{r.qwkrepsuccess}', qwkrepwake ='#{r.qwkrepwake}', \
           f_msgid = '#{r.f_msgid}' WHERE rec = 1")
end

def fetch_system

  res = @db.exec("SELECT * FROM system WHERE rec = 1") 

  temp = result_as_array(res).flatten

  t_lastqwkrep 		= temp[0]
  t_qwkrepsuccess 	= db_true(temp[1])
  t_qwkrepwake 	= temp[2]
  t_f_msgid 		= temp[4].to_i
  result = DB_system.new(t_lastqwkrep,t_qwkrepsuccess,t_qwkrepwake,t_f_msgid)

  return result


end

def rep_table(network)

  result = []
  res = @db.exec("SELECT netnum, name FROM areas ORDER BY number")
  temp = result_as_array(res)

  temp.each_with_index {|o,i|
    if o[0].to_i >= 0 then
      result << Area_rep.new(o[0].to_i,o[1],i)
    end
  }

  return result
end
