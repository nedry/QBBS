
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



class DB_system

  def initialize (lastqwkrep,qwkrepsuccess,qwkrepwake,f_msgid)
    @lastqwkrep		= lastqwkrep
    @qwkrepsuccess	= qwkrepsuccess
    @qwkrepwake		= qwkrepwake
    @f_msgid		= f_msgid

  end

  attr_accessor :lastqwkrep, :qwkrepsuccess, :qwkrepwake, :f_msgid
end
