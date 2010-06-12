require 'tools.rb'


class Module
  # synchronised readers
  def sync_reader(mutexname, *args)
    args.each {|var|
      module_eval <<-here
      def #{var.to_s}
        #{mutexname}.synchronize {@#{var.to_s}}
      end
      here
    }
  end
  private :sync_reader
end

#logging functions. class must provide @log supporting @log.line.push
module Logger
  def log(string)
    @log.line.push string
  end

  def writelog(logfile)
    fname = TEXTPATH + logfile
    if @log.line.length > 0 then
      lf = File.new(fname, File::CREAT|File::APPEND|File::RDWR, 0644)
      @log.line.each {|x|
        if x == "REWRITE" then
          lf.close
          rewritelog(logfile)
          lf = File.new(fname, File::CREAT|File::APPEND|File::RDWR, 0644)
        else
          lf.puts x
        end
      }
      @log.line.clear
      lf.close
    end
  end

  def rewritelog(logfile)
    fname = TEXTPATH + logfile
    if File.exists?(fname) then
      lf = File.new(fname, File::TRUNC|File::RDWR, 0644)
      lf.close
    end
  end
end

#base class for channel, user etc lists
class Listing
  include Enumerable

  def initialize
    @mutex = Mutex.new
    @list = Array.new
  end

  def each
    @list.each {|n| yield n}
  end

  def each_index
    @list.each_index {|i| yield i}
  end

  def each_with_index
    @list.each_with_index {|n,i| yield n,i}
  end

  def findkey(key)
    @mutex.synchronize {
      key.kind_of?(Integer) ?  @list[key] :
      @list.find {|v| key == yield(v)}
    }
  end

  def clear
    @mutex.synchronize {
      @list.clear
      self
    }
  end

  def append(val)
    @mutex.synchronize {
      @list.push(val)
      self
    }
  end

  def delete(val)
    @mutex.synchronize {
      @list.delete_at(val)
      self
    }
  end

  def len
    return @list.length
  end

  def savelist(filename)
    @mutex.synchronize {
      File.open(filename, "w+") do |f|
        Marshal.dump( @list, f) ##
      end
    }
  end

  def loadlist(filename, listname)
    @mutex.synchronize {
      puts "-SA: Loading #{listname}"

      if File.exists?(filename)
        File.open(filename) do |f|
          @list = Marshal.load(f)  ##
        end
      else
        @list = defaultlist
        print "-SA: #{listname.capitalize} not Found.  Creating new #{listname}\n"
        File.open(filename, "w+") do |f|
          Marshal.dump(@list, f) ##
          print "-SA: Saving #{listname}...\n"
        end
      end
    }
  end
end




Awho = Struct.new('Awho', :irc, :node, :level, :location,:where, :threadn, :date, :name, :page)
class Awho
  private :initialize
  class << self
    def create(name,irc,node,location,threadn,level,where)
      a = self.new
      a.date		= Time.now
      a.irc			= irc
      a.node		= node
      a.name		= name
      a.location		= location
      a.threadn		= threadn
      a.level		= level
      a.where		= where
      a.page    = []
      return a
    end
  end
end

class Who < Listing
  def initialize
    super
  end

  sync_reader '@mutex', :irc, :node, :date, :threadn, :location, :name, :level, :where, :page

  def [](key)
    findkey(key) {|who| who.threadn}
  end

  def user(key)
    findkey(key.upcase) {|who| who.name.upcase}
  end
end   #of Class Who

Airc_who = Struct.new('Airc_who', :where,  :date, :name, :page)
class Airc_who
  private :initialize
  class << self
    def create(name,where)
      a = self.new
      a.date		= Time.now
      a.name		= name
      a.where		= where
      a.page    = []
      return a
    end
  end
end

class Irc_who < Listing
  def initialize
    super
  end

  sync_reader '@mutex', :date, :name, :where, :page


  def user(key)
    findkey(key.upcase) {|who| who.name.upcase}
  end
end   #of Class Who

class Parse
  class << self
    def parse(input)
      temp = input.scan(/\d+/)
      [0,1].map {|i| (temp[i] || -1).to_i}
    end
  end
end


class Cmdstack
  def initialize
    @cmd = Array.new
  end

  attr_accessor :cmd

  def pullapart (input)
    happy = input.split(/\s*;\s*/)
    @cmd = happy if happy
  end
end #of def

class Log
  def initialize
    @line = Array.new
    @mutex = Mutex.new
  end

  attr_accessor :line
  sync_reader '@mutex', :line
end #of class Log

class LineEditor
  def initialize
    @msgtext 	= []
    @line		= 0
    @save		= false
  end
  attr_accessor :msgtext, :line, :save
end




Message_qwk = Struct.new('Message_qwk',:error, :statusflag, :number, :date,
:to, :from, :subject, :password, :reference, :blocks, :deleted, :logicalnum,
:tagline, :text)
class Message_qwk
  private :initialize
  class << self
    def create
      a = self.new
      a.error = false
      a.statusflag = ''
      a.number = 0
      a.date = Time.new
      a.to = ''
      a.from = ''
      a.subject = ''
      a.password = ''
      a.reference = 0
      a.blocks = 0
      a.deleted = false
      a.logicalnum = 0
      a.tagline = false
      a.text = []
      return a
    end
  end
end #of message

class Area_qwk
  def initialize (area,name)
    @area = area
    @name = name
  end

  attr_accessor :area, :name
end

class Area_rep
  def initialize (xnum,name,num)
    @xnum = xnum
    @name = name
    @num = num
  end

  attr_accessor :xnum, :name, :num
end

class F_export
  def initialize (num,table)
    @table = table
    @num = num
  end

  attr_accessor :table, :num
end


class Arealist_qwk
  def initialize
    @arealist_qwk = Array.new
  end

  attr_reader :area, :name

  def append(aArea)
    @arealist_qwk.push(aArea)
  end

  def [](key)
    key.kind_of?(Integer) ? @arealist_qwk[key] :
    @arealist_qwk.find {|arealist| key == arealist.name}
  end

  def findarea(key)
    @arealist_qwk.find { |arealist| key == arealist.area }
  end

  def len
    @arealist_qwk.length
  end
end #of Class Arealist

