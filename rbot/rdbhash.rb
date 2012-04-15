begin
  require 'bdb'
rescue Exception => e
  puts "oh fuck"
  #error "Got exception: "+e
#  error "rbot couldn't load the bdb module, perhaps you need to install it? try: http://www.ruby-lang.org/en/raa-list.rhtml?name=bdb"
  exit 2
end

# make BTree lookups case insensitive
module BDB
  class CIBtree < Btree
    def bdb_bt_compare(a, b)
      if a == nil || b == nil
        warning "CIBTree: comparing #{a.inspect} (#{self[a].inspect}) with #{b.inspect} (#{self[b].inspect})"
      end
      (a||'').downcase <=> (b||'').downcase
    end
  end
end

#module Irc

  # DBHash is for tying a hash to disk (using bdb).
  # Call it with an identifier, for example "mydata". It'll look for
  # mydata.db, if it exists, it will load and reference that db.
  # Otherwise it'll create and empty db called mydata.db
  class DBHash

    # absfilename:: use +key+ as an actual filename, don't prepend the bot's
    #               config path and don't append ".db"
    def initialize(bot, key, absfilename=false)
      @bot = bot
      @key = key
      if absfilename && File.exist?(key)
        # db already exists, use it
        @db = DBHash.open_db(key)
      elsif File.exist?("rbot_data" + "/#{key}.db")
        # db already exists, use it
        @db = DBHash.open_db("rbot_data" + "/#{key}.db")
      elsif absfilename
        # create empty db
        @db = DBHash.create_db(key)
      else
        # create empty db
        @db = DBHash.create_db("rbot_data" + "/#{key}.db")
      end
    end

    def method_missing(method, *args, &block)
      return @db.send(method, *args, &block)
    end

    def DBHash.create_db(name)
      puts  "-DBHash: creating empty db #{name}"
      return BDB::Hash.open(name, nil, 
      BDB::CREATE | BDB::EXCL, 0600)
    end



   
    def DBHash.open_db(name)
      puts  "-DBHash: opening existing db #{name}"
      return BDB::Hash.open(name, nil, "r+", 0600)
    end

  end


  # DBTree is a BTree equivalent of DBHash, with case insensitive lookups.
  class DBTree
    @@env=nil
    # TODO: make this customizable
    # Note that it must be at least four times lg_bsize
    @@lg_max = 8*1024*1024
    # absfilename:: use +key+ as an actual filename, don't prepend the bot's
    #               config path and don't append ".db"
    
    def initialize(bot, key, absfilename=false)

      @bot = bot
      @key = key
      if @@env.nil?
        begin
          @@env = BDB::Env.open("rbot_data", BDB::INIT_TRANSACTION | BDB::CREATE | BDB::RECOVER, "set_lg_max" => @@lg_max)
          puts "DBTree: environment opened with max log size #{@@env.conf['lg_max']}"
        rescue => e
          puts "DBTree: failed to open environment: #{e}. Retrying ..."
          @@env = BDB::Env.open("rbot_data", BDB::INIT_TRANSACTION | BDB::CREATE |  BDB::RECOVER)
        end
        #@@env = BDB::Env.open("rbot_data", BDB::CREATE | BDB::INIT_MPOOL | BDB::RECOVER)
      end

      if absfilename && File.exist?(key)
        # db already exists, use it
        @db = DBTree.open_db(key)
      elsif absfilename
        # create empty db
        @db = DBTree.create_db(key)
      elsif File.exist?("rbot_data" + "/#{key}.db")
        # db already exists, use it
        @db = DBTree.open_db("rbot_data" + "/#{key}.db")
      else
        # create empty db
        @db = DBTree.create_db("rbot_data" + "/#{key}.db")
      end
    end


   
    def method_missing(method, *args, &block)
      return @db.send(method, *args, &block)
    end

    def DBTree.create_db(name)
      puts  "DBTree: creating empty db #{ROOT_PATH}#{name}"
      return @@env.open_db(BDB::CIBtree, "#{ROOT_PATH}#{name}", nil, BDB::CREATE | BDB::EXCL, 0600)
    end

    def DBTree.open_db(name)
      puts  "DBTree: opening existing db #{ROOT_PATH}#{name}"
      return @@env.open_db(BDB::CIBtree, "#{ROOT_PATH}#{name}", nil, "r+", 0600)
    end

    def DBTree.cleanup_logs()
      begin
        puts  "DBTree: checkpointing ..."
        @@env.checkpoint
      rescue => e
        puts  "Failed: #{e}"
      end
      begin
        puts  "DBTree: flushing log ..."
        @@env.log_flush
        logs = @@env.log_archive(BDB::ARCH_ABS)
        puts  "DBTree: deleting archivable logs: #{logs.join(', ')}."
        logs.each { |log|
          File.delete(log)
        }
      rescue => e
        puts  "Failed: #{e}"
      end
    end

    def DBTree.stats()
      begin
        puts  "General stats:"
        puts  @@env.stat
        puts  "Lock stats:"
        puts  @@env.lock_stat
        puts  "Log stats:"
        puts  @@env.log_stat
        puts  "Txn stats:"
        puts  @@env.txn_stat
      rescue
        puts  "Couldn't dump stats"
      end
    end

    def DBTree.cleanup_env()
      begin
        puts  "DBTree: checking transactions ..."
        has_active_txn = @@env.txn_stat["st_nactive"] > 0
        if has_active_txn
          warning "DBTree: not all transactions completed!"
        end
        DBTree.cleanup_logs
        puts  "DBTree: closing environment #{@@env}"
        path = @@env.home
        @@env.close
        @@env = nil
        if has_active_txn
          puts  "DBTree: keeping file because of incomplete transactions"
        else
          puts  "DBTree: cleaning up environment in #{path}"
          BDB::Env.remove("#{path}")
        end
      rescue => e
        error "failed to clean up environment: #{e.inspect}"
      end
    end

  end

#end
