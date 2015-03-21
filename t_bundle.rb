##############################################
#
#   t_bundle.rb --Bundle Processor for Fidomail tosser for QBBS.
#   (C) Copyright 2004, Fly-By-Night Software (Ruby Version)
#
##############################################

require "pg_ext"
require "consts.rb"
require "t_class.rb"
require "t_const.rb"
require "t_pktread.rb"
require "db/db_area"
require "db/db_message"


def folder_by_date
  folder = Time.now.strftime("%d%m%y")
  return folder
end

def write_a_ilo
  ilo_name = "#{SPOOL}/#{H_FIDONET.to_s(16).rjust(4).gsub!(32.chr,"0")}#{H_FIDONODE.to_s(16).rjust(4).gsub!(32.chr,"0")}.ilo"
  happy = system("touch #{ilo_name} > /dev/null 2>&1")
  @debuglog.push( "-BUNDLE: Ilo file did not create!") if !happy
end

def name_a_bundle
  folder = folder_by_date
  system("mkdir #{BACKUPOUT}/#{folder} > /dev/null 2>&1")
  t_name = "#{H_FIDONET.to_s(16).rjust(4).gsub!(32.chr,"0")}#{H_FIDONODE.to_s(16).rjust(4).gsub!(32.chr,"0")}"
  day = Time.now.strftime("%a").slice(0..1).downcase
  #Dir.chdir("#{TEMPOUTDIR}")
  entries = Dir["#{BACKUPOUT}/#{folder}/#{t_name}.#{day}?"]
  if entries.length == 0 then
    ext = "0"
  else
    rec = entries.last
    last = rec[rec.length - 1].chr
    ext = last.succ
    ext = "a" if ext == "10"
    return OUTOFBUNDLES if ext == "aa" #this is the succ to "z", and means we have too many packets
  end
  name = "#{t_name}.#{day}#{ext}"
  return name
end

def copy_bundles
  entries = Dir["*"]
  if entries.length > 0 then
    happy = system("mv -f #{TEMPOUTDIR}/* #{BUNDLEOUTDIR} > /dev/null 2>&1")
    if happy then return SUCCESS else return BUNDLE_MOVE_ERROR end
  else
    return NO_BUNDLE_TO_COPY
  end
end

def bundle_it
  bundle_name = name_a_bundle
  folder = folder_by_date
  if bundle_name != OUTOFBUNDLES then
    entries = Dir["#{TEMPOUTDIR}/*.pkt"]

    if entries.length > 0 then
      @debuglog.push( "-BUNDLE: Bundling #{entries.length} packets in #{bundle_name}")
      happy = system("zip -j -m #{TEMPOUTDIR}/#{bundle_name} #{TEMPOUTDIR}/*.pkt > /dev/null 2>&1")
      happy = system("cp -f #{TEMPOUTDIR}/* #{BACKUPOUT}/#{folder} > /dev/null 2>&1")
      return SUCCESS
    else
      @debuglog.push( "-BUNDLE:No packets found!")
      return NO_PACKETS_ERROR
    end
  else
    @debuglog.push( "-BUNDLE:Error.  Out of Bundles!")
  end
end

def bundle
  result = bundle_it
  result = copy_bundles if result == SUCCESS
end

def check_for_packets
  entries = Dir["#{BUNDLEINDIR}/*"]
  if entries.length > 0 then
    @debuglog.push( "-BUNDLE: Found #{entries.length} bundles to import.")
		#we don't need these files unless we are a hub which we aren't so... move them so they don't confuse the unbundler...
    system ("mv -f #{BUNDLEINDIR}/*.tic #{BACKUPIN} > /dev/null 2>&1")
    system ("mv -f #{BUNDLEINDIR}/nodelist.* #{BACKUPIN} > /dev/null 2>&1")
		
    entries.each {|entry|
      happy = system("cp -f #{entry} #{BACKUPIN} > /dev/null 2>&1")
      happy = system("mv -f #{entry} #{TEMPINDIR} > /dev/null 2>&1")
    }
    return SUCCESS
  else
    @debuglog.push( "-BUNDLE: No Incoming Bundles")
    return NO_BUNDLES_ERROR
  end
end


def process_packets
  entries = Dir["#{PKTTEMP}/*.pkt"]
  entries2 = Dir["#{PKTTEMP}/*.PKT"]
  c_entries = entries + entries2

  if c_entries.length > 0 then
    c_entries.each { |entry|
      @debuglog.push( "-BUNDLE: Processing packet #{entry}")
      process_packet("#{entry}")
    }
    c_entries.each {|entry| system("rm #{entry} > /dev/null 2>&1")}
  end
end

def process_incoming_pkt
  override = false
  entries = Dir["#{BUNDLEINDIR}/*.pkt"]
  entries2 = Dir["#{BUNDLEINDIR}/*.PKT"]
  c_entries =  entries + entries2

  if c_entries.length > 0 then
    override = true
    c_entries.each { |entry|
      @debuglog.push( "-BUNDLE: Moving packet #{entry}")
      system("cp -f #{entry} #{BACKUPIN} > /dev/null 2>&1")
      system("mv -f #{entry} #{PKTTEMP} > /dev/null 2>&1")
    }
    process_packets
  end
end

def process_incoming
  result = check_for_packets
  if result == SUCCESS then
    entries = Dir["#{TEMPINDIR}/*"]
    if entries.length > 0 then
      entries.each {|entry|
        @debuglog.push( "-BUNDLE: Uncompressing bundle #{entry}")
        happy = system("unzip -o -j #{entry} -d #{PKTTEMP} > /dev/null 2>&1")
        if !happy then
          @debuglog.push( "-BUNDLE: Unzip Failure.  Oh shit!")
          return UNZIP_FAILURE
        end
        @debuglog.push( "-BUNDLE: Processing Bundle: #{entry}")
        process_packets
        system("rm #{entry} > /dev/null 2>&1")
      }

    else
      @debuglog.push( "-BUNDLE: No Bundles!")
      return NO_BUNDLES_ERROR
    end
  end
end

def unbundle
  process_incoming_pkt
  process_incoming
end
