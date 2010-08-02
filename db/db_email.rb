def e_total(user)
  Message.all(:number => 0,  :conditions => ["m_to ILIKE ?", user] ).count
end


def new_email(ind,user)

  ind = 0 if ind.nil?
  Message.all(:number => 0, :absolute.gt => ind,  :conditions => ["m_to ILIKE ?", user] ).count
  #res = @db.exec("SELECT COUNT(*) FROM messages WHERE absolute > #{ind} and upper(m_to) = '#{user.upcase}' and number = '0'")
  #result = single_result(res).to_i
end


def email_absolute_message(ind,m_to)
  ind = 0 if ind.nil?
  lazy_list = Message.all(:number => 0, :conditions => ["m_to ILIKE ?", m_to] , :order => [ :absolute ])
  result = lazy_list[ind-1].absolute
end

