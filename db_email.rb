

def e_total(table,user)
  res = @db.exec("SELECT COUNT(*) FROM #{table} WHERE lower(m_to) = '#{user.downcase}'")
  result = single_result(res).to_i
  return result
end

def find_epointer(hash,absolute,table,user)

  total = (e_total(table,user) - 1 )
  for i in 0..total
    result = i
    return result + 1 if hash[i] >= absolute.to_i
  end
  return nil
end



def email_lookup_table(table,user)

  hash = []

  res = @db.exec("SELECT number FROM #{table} WHERE lower(m_to) = '#{user.downcase}' ORDER BY number")
  hash = result_as_array(res).flatten
  for i in 0..hash.length-1
    hash[i] = hash[i].to_i
  end

  #hash.each {|x| puts "email hash #{x}"}

  hash = nil if hash.length < 1

  return hash
end


def new_messages(table,ind)

  #puts "ind:#{ind}"

  #row = @db.exec("SELECT COUNT(*) FROM #{table} WHERE number > #{ind}")
  res = @db.exec("SELECT COUNT(*) FROM #{table} WHERE number > #{ind}")
  result = single_result(res).to_i
  return result
end

def delete_msg(table,ind)

  @db.exec("DELETE FROM #{table} WHERE number = '#{ind}'")
end


