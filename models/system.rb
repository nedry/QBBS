class System
  include DataMapper::Resource
  storage_names[:default] = 'system'

  property :id, Serial
  property :lastqwkrep, DateTime
  property :qwkrepsuccess, Boolean 
  property :qwkrepwake, DateTime
  property :total_logons, Integer, :min => 0, :max => 2**32, :default => 0
  property :logons_today, Integer, :min => 0, :max => 2**32, :default => 0
  property :posts_today, Integer, :min => 0, :max => 2**32, :default => 0
  property :emails_today, Integer, :min => 0, :max => 2**32, :default => 0
  property :feedback_today, Integer, :min => 0, :max => 2**32, :default => 0
  property :newu_today, Integer, :min => 0, :max => 2**32, :default => 0
  property :rec, Integer, :default => 1  
  property :f_msgid, Integer, :min => 0, :max => 2**32
end
