require 'models/message'
require 'models/area'
require 'dm-validations'
require 'consts.rb'
require 'encodings.rb'

def scanforaccess(user)
  for i in 0..(a_total - 1) do
    area = fetch_area(i)
    pointer = get_pointer(user,i)
    if pointer.nil? then
      add_pointer(user,i,area.d_access,0)
    end
  end
end

def m_total(area)
  Message.all(:number => area).count
end

def new_messages(area,ind)
  ind = 0 if ind.nil?
  Message.all(:absolute.gt => ind, :number => area).count
end

def absolute_message(area,ind)
  ind = 0 if ind.nil?
  lazy_list = Message.all(:number => area, :order => [ :absolute ])
  result = lazy_list[ind-1].absolute
end

def high_absolute(table)
  if m_total(table) > 0 then
    result = absolute_message(table,m_total(table))
  else result = 0 end
  return result
end

def delete_msg(ind)
  message = Message.first(:absolute => ind)
  message.destroy!
end

def delete_msgs(area,first,last)
  message = Message.all(:absolute.gte => first, :absolute.lte => last, :number => area)
  message.destroy!
end

def find_fido_area(area)
  area = Area.first(:fido_net => area)
  number = area.number
  return number
end

def exported(absolute)
  message = Message.first(:absolute => absolute)
  message.exported = true
  message.save!
end

def update_msg(r)
  r.save
end

def fetch_msg(absolute)
  message = Message.first(:absolute => absolute)
end

def e_total(user)
  Message.all(:number => 0,  :conditions => ["m_to ILIKE ?", user] ).count
end

def new_email(ind,user)
  ind = 0 if ind.nil?
  Message.all(:number => 0, :absolute.gt => ind, :conditions => ["m_to ILIKE ?", user]).count
end


def email_absolute_message(ind,m_to)
  ind = 0 if ind.nil?
  lazy_list = Message.all(:number => 0, :conditions => ["m_to ILIKE ?", m_to], :order => [:absolute ])
  result = lazy_list[ind-1].absolute
end

def add_msg(m_to,m_from,msg_date,subject,msg_text,exported,network,reply,destnode,destnet,intl,topt,smtp,number)

  topt = -1 if topt.nil?
  destnode = -1 if destnode.nil?
  destnet = -1 if destnet.nil?
  area = Area.first(:number => number)
  message = area.messages.new(
    :m_to => m_to,
    :m_from => m_from,
    :msg_date => msg_date,
    :subject => subject,
    :msg_text => msg_text, 
    :exported => exported,
    :network => network,
    :reply => reply,
    :destnode => destnode,
    :destnet => destnet,
    :intl => intl,
    :topt => topt,
    :smtp => smtp
  ) 
  dude = message.save
  #message.errors.each{|x| puts x}
  #puts "worked: #{dude}"
  return high_absolute(area.number)
end

def add_qwk_message(message, area)
  user = fetch_user(get_uid(QWKUSER))
  pointer = get_pointer(user,area.number)
  msg_text = message.text
  to = message.to.upcase.strip
  m_from = message.from.upcase.strip
  msg_date = message.date
  title = message.subject.strip
  exported = true
  network = true
  absolute = add_msg(to,m_from,msg_date,title,msg_text,exported,network,false,nil,nil,nil,nil,false,area.number)

  user.posted = user.posted + 1
  pointer.lastread = absolute
  update_pointer(pointer)
  update_user(user)
end

def convert_to_utf8(message)
  temp = message.gsub(227.chr,"\r") #replace qwk delimilter with cr
  temp2 = ""
  temp2.force_encoding("UTF-8")
  for i in 0..temp.length - 1 do
    if temp[i].ord <= 127 then
      temp2 << temp[i]
    else
      temp2 << Encodings::ASCII_UNICODE[temp[i]]
    end
  end
  return temp2
end

def convert_to_ascii(message)
  temp = ""
  temp.force_encoding("ASCII-8BIT")

  for i in 0..message.length - 1 do
    if message[i].ord <= 127 then
      temp << message[i]
    else
      temp << Encodings::UNICODE_ASCII[message[i]]
    end
  end
  return temp
end
