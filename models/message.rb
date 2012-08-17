

class Message
  include DataMapper::Resource
  storage_names[:default] = 'messages'

  property :absolute, Serial
  property :delete, Boolean, :default => false
  property :locked, Boolean, :default => false 
  property :m_to, String, :length => 40
  property :m_from, String, :length => 40
  property :msg_date, DateTime
  property :subject, String, :length => 80
  property :msg_text, Text
  property :exported, Boolean, :default => false
  property :network, Boolean, :default => false
  property :f_network, Boolean, :default => false
  property :orgnode, Integer
  property :destnode, Integer
  property :orgnet, Integer
  property :destnet, Integer
  property :attribute, Integer
  property :cost, Integer
 # property :area, String, :length => 80
  property :msgid, String, :length => 80 
  property :path, String, :length => 80
  property :tzutc, String, :length => 10
  property :charset, String, :length => 10
  property :tid, String, :length => 80
  property :pid, String, :length => 80
  property :intl, String, :length => 80
  property :topt, Integer
  property :fmpt, Integer 
  property :reply, Boolean, :default => false 
  property :origin, String, :length => 80
  property :smtp, Boolean, :default => false 
  property :nntp, Boolean, :default => false 
  property :number, Integer,  :min => 0, :max => 2**32,  :key => true
  property :q_msgid, String, :length => 80
  property :q_tz, String, :length => 40
  property :q_via, String, :length => 255
  property :q_reply, String, :length => 255
  
  property :apparentlyto, String, :length => 255
  property :xcommentto, String, :length => 255    
  property :newsgroups, String, :length => 255  
  property :newsgroups, String, :length => 255 
  property :organization, String, :length => 255
  property :replyto, String, :length => 255  
  property :inreplyto, String, :length => 255
  property :organization, String, :length => 255
  property :bytes, Integer,  :min => 0, :max => 2**32
  property :lines, Integer,  :min => 0, :max => 2**32
  property :xref, String, :length => 255
  property :messageto, String, :length => 255
  property :references, String, :length => 255
  property :xgateway, String, :length => 255
  property :control, String, :length => 255
  property :contenttype, String, :length => 255
  property :contenttransferencoding, String, :length => 255
  property :nntppostinghost, String, :length => 255
  property :xcomplaintsto, String, :length => 255
  property :xtrace, String, :length => 255
  property :nntppostingdate, String, :length => 40
  property :xoriginalbytes, String, :length => 255
  property :fntarea, String, :length => 255
  property :fntflags, String, :length => 255  
  property :path, String, :length => 512
 
  belongs_to :area, :child_key => [:number]
  end
