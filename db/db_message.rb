require 'models/message'
require 'models/area'
require 'dm-validations'

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

#def absolute_message(area,ind)
#  ind = 0 if ind.nil?
#  @db.exec("BEGIN")
#  @db.exec("DECLARE c CURSOR FOR SELECT absolute FROM messages WHERE number = '#{area}' ORDER BY absolute")
#  @db.exec("MOVE FORWARD #{ind+1} IN c")
# res =  @db.query("FETCH BACKWARD 1 IN c")
#  result = single_result(res).to_i
#  @db.exec("CLOSE c")
#  @db.exec("END")
#  puts "result: #{result}"
#  return result
#end

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

  #@db.exec("DELETE FROM messages WHERE number >= '#{first}' and number <= '#{last}' and tbl = '#{area}'")
end

def find_fido_area (area)

  #table = nil
  #area.strip! if !area.nil?
  area = Area.first(:fido_net => area)
  #res = @db.exec("SELECT tbl,number FROM areas WHERE fido_net = '#{area}'")
  #temp = result_as_array(res).flatten
  number = area.number
  return number
end

def exported(absolute)
   message = Message.first(:absolute => absolute)
   message.exported = true
   message.save!
  #@db.exec("UPDATE messages SET exported = true WHERE number = #{number}")
end

def update_msg(r)
 r.save
end


def fetch_msg(absolute)
  message = Message.first(:absolute => absolute)
 end



def add_msg(m_to,m_from,msg_date,subject,msg_text,exported,network,reply,destnode,destnet,intl,topt,smtp,number)

  topt = -1 if topt.nil?
  destnode = -1 if destnode.nil?
  destnet = -1 if destnet.nil?
   puts "number: #{number}"
   area = Area.get(number)
   puts "area: #{area}"
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
 message.errors.each{|x| puts x}
 puts "worked: #{dude}"
           return high_absolute(area)
end
