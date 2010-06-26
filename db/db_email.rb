

def e_total(table,user)
  res = @db.exec("SELECT COUNT(*) FROM #{table} WHERE lower(m_to) = '#{user.downcase}'")
  result = single_result(res).to_i
  return result
end


def new_email(table,ind,user)

  #puts "ind:#{ind}"
  ind = 0 if ind.nil?

  res = @db.exec("SELECT COUNT(*) FROM #{table} WHERE number > #{ind} and upper(m_to) = '#{user.upcase}'")
  result = single_result(res).to_i
end

def email_absolute_message(table,ind,m_to)
  ind = 0 if ind.nil?
  @db.exec("BEGIN")
  @db.exec("DECLARE c CURSOR FOR SELECT number FROM #{table} WHERE lower(m_to) = '#{m_to.downcase}' ORDER BY number")
  @db.exec("MOVE FORWARD #{ind+1} IN c")
  res =  @db.query("FETCH BACKWARD 1 IN c")
  result = single_result(res).to_i
  @db.exec("CLOSE c")
  @db.exec("END")
  return result
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
