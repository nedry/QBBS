
class DB_who

 def initialize(number,lastactivity,place)

	@number=number
	@lastactivity=time.now
	@place=place
end

	attr_accessor :number,:lastactivity,:place
end 


class DB_who_T
	 def initialize(irc,node,name,location,where,page)

			@date		= Time.now
			@irc			= irc
			@node		= node
			@name		= name
			@location	= location
			@where		= where
			@page    = []
		end
	attr_accessor :date, :irc, :node, :name, :location, :where, :page
end
 
class DB_user


  	   
 def initialize( deleted, locked, name, alais, ip, citystate, address, password,
  	   length, modify_date, width, ansi,more, level, areaaccess, lastread,
  	   createdate, laston, logons, posted,rsts_pw, rsts_acc, fullscreen, zipread,
  	   signature)
			@deleted	= false 
			@locked 	= false 
			@name  	= name 
			@alais	=  alais
			@ip   	= ip
			@citystate	= citystate 
			@address 	= address 
			@password = password 
			@length 	= length
			@width 	= 80 
			@ansi 	= ansi
			@more 	= more
			@level	= level
			@areaaccess = areaaccess
			@lastread	= lastread
			@newmsg	= []   #this is updated dynamically at area-change
			@create_date	= Time.now
			@modify_date	= Time.now
			@laston	= Time.now
			@logons	= 0
			@posted	= 0
			@page	= []
			@channel	= 0
			@rsts_pw	= ""
			@rsts_acc	= 0
			@fullscreen = fullscreen
			@zipread       = zipread
			@signature  = signature
		
		end
	attr_accessor :create_date, :deleted, :alais, :ip, :locked, :name, :phone,
		:citystate, :address, :password, :length, :width, :ansi, :more, :level,
		:areaaccess, :modify_date, :laston, :lastread, :newmsg, :logons, :posted, :page,
		:pageuser, :channel,:rsts_pw, :rsts_acc, :fullscreen, :zipread, :signature
	end 

class DB_area_list

 def initialize (name,delete,number,group,tbl)
  @name		= name
  @delete		= delete
  @number		= number
  @group		= group
  @tbl			= tbl
 end

  attr_accessor :name, :delete, :number, :group, :tbl
end

class DB_area

 def initialize (name,tbl,delete,locked,number,netnum,d_access,v_access,modify_date,network,fido_net,group)
  @name		 	= name
  @tbl			= tbl
  @delete		= delete
  @locked	 	= locked
  @number		= number
  @netnum		= netnum
  @d_access	 	= d_access
  @v_access	 	= v_access
  @modify_date		= modify_date
  @network		= network
  @fido_net		= fido_net
  @group		= group
  
 end

  attr_accessor :name, :tbl, :delete, :locked, :number, :netnum, :d_access, :v_access, :modify_date, :network, :fido_net, :group
end
class DB_message

def initialize (delete,locked,number,m_to,m_from,msg_date,subject,msg_text,exported,network,f_network,
		orgnode,destnode,orgnet,destnet,attribute,cost,area,msgid,
		path, tzutc,charset,tid,pid,intl,topt,fmpt,reply,origin,smtp)
 
  @delete	= delete
  @locked	= locked
  @number	= number
  @m_to	 	= m_to
  @m_from	= m_from
  @msg_date	= msg_date
  @subject	= subject
  @msg_text	= msg_text
  @exported	= exported
  @network      = network
  @f_network	= f_network
  # FidoNet Stuff (wow, more than my stuff)
  @orgnode	= orgnode
  @destnode	= destnode
  @orgnet	= orgnet
  @destnet	= destnet
  @attribute	= attribute
  @cost		= cost
  @area		= area
  @msgid	= msgid
  @path		= path
  @tzutc	= tzutc
  @charset	= charset
  @tid		= tid
  @pid		= pid
  @intl		= intl
  @topt		= topt
  @fmpt		= fmpt
  @reply	= reply
  @origin	= origin
  @smtp		= smtp
 end

  attr_accessor :delete, :locked, :number, :m_to, :m_from, :msg_date, :subject, :msg_text, 
		  :exported, :network, :f_network, :orgnode, :destnode, :orgnet, :destnet, :attribute, :cost, 
		  :area, :msgid, :path, :tzutc, :charset, :tid, :pid, :intl, :topt, :fmpt,
		  :reply, :origin, :smtp
end

class DB_bulletin

def initialize (name,locked,number,modify_date,path)

  @name	 	= name
  @locked		= locked
  @number		= number
  @modify_date	= modify_date
  @path		= path
 end

  attr_accessor :name, :locked, :number, :modify_date, :path
end

class DB_doors

 def initialize (name,locked,number,modify_date,d_path,d_type,path,level,droptype)
  @name		= name
  @locked	 	= locked
  @number		= number
  @modify_date	= modify_date
  @d_path		= d_path
  @d_type		= d_type
  @path		= path
  @level		= level
  @droptype	= droptype
  
 end

  attr_accessor :name, :locked, :number,  :modify_date, :d_path, :d_type, :path, :level, :droptype
end

class DB_other

 def initialize (name,locked,number,modify_date,address,level)
  @name		= name
  @locked	= locked
  @number	= number
  @modify_date	= modify_date
  @address	= address
  @level	= level
  
 end

  attr_accessor :name, :locked, :number,  :modify_date, :address,  :level
end

class DB_system

 def initialize (lastqwkrep,qwkrepsuccess,qwkrepwake,f_msgid)
  @lastqwkrep		= lastqwkrep
  @qwkrepsuccess	= qwkrepsuccess
  @qwkrepwake		= qwkrepwake
  @f_msgid		= f_msgid

 end

  attr_accessor :lastqwkrep, :qwkrepsuccess, :qwkrepwake, :f_msgid
end

class DB_group

 def initialize (number,groupname)
  @number		= number
  @groupname		= groupname
  
 end

  attr_accessor :number, :groupname
end