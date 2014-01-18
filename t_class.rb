class Packet_header_two  		# Fidonet Packet Header

  def initialize (orgnode,destnode,year,month,day,hour,min,sec,pkttype,
    orgnet,destnet,prodcode,sernum,password,orgzone,
    destzone,auxnet,cwcopy,revision,cword,orgpoint,
    destpoint)
    @orgnode	= orgnode	#Origination Node of Packet
    @destnode	= destnode	#Destination Node of Packet
    @year		= year		#Year of Packet Creation e.g. 1995
    @month		= month		#Month of Packet Creation 0-11
    @day		= day		#Day of Packet Creation 1-31
    @hour 		= hour		#Hour of Packet Creation 0-23
    @min		= min		#Minute of Packet Creation 0-59
    @sec		= sec		#Second of Packet Creation 0-59
    @baud		= baud		#Max Baud Rate of Orig & Dest
    @pkttype	= pkttype		#Packet Type (-1 is obsolete)
    @orgnet	= orgnet		#Origination Net of Packet
    @destnet	= destnet	#Destination Net of Packet
    @prodcode	= prodcode	#Product Code (00h is Fido)
    @sernum	= sernum		#Binary Serial Number or nil
    @password	= password	#Session Password or nil (8 characters)
    @orgzone	= orgzone	#Origination Zone of Packet or nil
    @destzone	= destzone	#Destination Zone of Packet or NULL

    @auxnet	= auxnet		#Orig Net if Origin is a Point
    @cwcopy	= cwcopy		#Must be Equal to cword
    @revision	= revision	#Revision
    @cword		= cword		#Compatibility Word
    @orgpoint	= orgpoint	#Origination Point
    @destpoint	= destpoint	#Destination Point
  end

  attr_accessor :orgnode, :destnode, :year, :month, :day, :hour, :min,:sec,
  :baud, :pkttype, :orignet, :destnet, :prodcode, :sernum, :password,
  :orgnet, :destnet, :orgzone, :destzone, :auxnet, :cwcopy, :prodcode, :revision,
  :cword, :orgpoint, :destpoint


end # of class packet_header_two


class A_fidonet_message  		# An individual Fidonet Message

  def initialize (orgnode,destnode,orgnet,destnet,attribute,cost,datetime,
    to,from,subject,message,area,msgid,path,tzutc,charset,tid,
    pid,intl,topt,fmpt,reply,origin)
    @orgnode	= orgnode
    @destnode	= destnode
    @orgnet	= orgnet
    @destnet	= destnet
    @attribute	= attribute
    @cost		= cost
    @datetime	= datetime
    @to			= to
    @from		= from
    @subject		= subject
    @message	= message
    @area		= area
    @msgid		= msgid
    @path		= path
    @tzutc		= tzutc
    @charset		= charset
    @tid		= tid
    @pid		= pid
    @intl		= intl
    @topt		= topt
    @fmpt		= fmpt
    @reply		= reply
    @origin		= origin
  end

  attr_accessor :orgnode, :destnode, :orgnet, :destnet, :attribute,
  :cost, :datetime, :to, :from, :subject, :message, :area,
  :msgid, :path, :tzutc, :charset, :tid, :pid, :intl, :topt, :fmpt,
  :reply, :origin


end # of class A_fidonet_message

class Kludge
  attr_accessor :area, :msgid, :path, :tzutc, :charset, :tid, :pid, :intl, :topt,
  :fmpt, :reply, :origin

  def initialize (area=nil,msgid=nil,path=nil,tzutc=nil,
    charset=nil,tid=nil,pid=nil,intl=nil,
    topt=nil,fmtp=nil,reply=nil,origin=nil)
    @area 	= area
    @msgid	= msgid
    @path		= path
    @tzutc	= tzutc
    @charset	= charset
    @tid		= tid
    @pid		= pid
    @intl		= intl
    @topt		= topt
    @fmpt		= fmpt
    @reply		= reply
    @origin		= origin
  end

  def []=(field, value)
    field = field.downcase
    self.send("#{field}=", value)
  end

end #of class Kludge
