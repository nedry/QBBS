
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

class DB_system

  def initialize (lastqwkrep,qwkrepsuccess,qwkrepwake,f_msgid)
    @lastqwkrep		= lastqwkrep
    @qwkrepsuccess	= qwkrepsuccess
    @qwkrepwake		= qwkrepwake
    @f_msgid		= f_msgid

  end

  attr_accessor :lastqwkrep, :qwkrepsuccess, :qwkrepwake, :f_msgid
end
