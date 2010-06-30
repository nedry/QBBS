def e_total(user)
  res = @db.exec("SELECT COUNT(*) FROM messages WHERE lower(m_to) = '#{user.downcase}' and tbl = '0'")
  result = single_result(res).to_i
  return result
end


def new_email(ind,user)

  #puts "ind:#{ind}"
  ind = 0 if ind.nil?

  res = @db.exec("SELECT COUNT(*) FROM messages WHERE number > #{ind} and upper(m_to) = '#{user.upcase}' and tbl = '0'")
  result = single_result(res).to_i
end

def email_absolute_message(ind,m_to)
  ind = 0 if ind.nil?
  @db.exec("BEGIN")
  @db.exec("DECLARE c CURSOR FOR SELECT number FROM messages WHERE lower(m_to) = '#{m_to.downcase}' and tbl = '0' ORDER BY number")
  @db.exec("MOVE FORWARD #{ind+1} IN c")
  res = @db.query("FETCH BACKWARD 1 IN c")
  result = single_result(res).to_i
  @db.exec("CLOSE c")
  @db.exec("END")
  return result
end

def new_messages(table,ind)

  #puts "ind:#{ind}"

  #row = @db.exec("SELECT COUNT(*) FROM #{table} WHERE number > #{ind}")
  res = @db.exec("SELECT COUNT(*) FROM messages WHERE number > #{ind} and tbl = '0'")
  result = single_result(res).to_i
  return result
end

def delete_msg(ind)

  @db.exec("DELETE FROM messages WHERE number = '#{ind}'")
end