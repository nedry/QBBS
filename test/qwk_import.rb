# run from top level directory: 
# $ ruby test/qwk_import.rb

require 'fileutils'
require 'datamapper'
require 'consts'
require 'qwk'
require 'db/db_message'
require 'db/db_user'
require 'db/db_area'

QWK_DEBUG = true
DataMapper::Logger.new('log/db', :debug)
DataMapper.setup(:default, "postgres://#{DATAIP}/#{DATABASE}")

base = Dir.pwd
qdir = "#{base}/qwk"
FileUtils.mkdir(qdir) unless File.exist?(qdir)
`rm #{qdir}/*`
`unzip testdata/vert.qwk -d #{qdir}`

qi = Qwk::Importer.new(qdir)
idxlist = qi.getindexlist("qwk/*.NDX")
idxlist.each do |idx|
  index = qi.read_index(idx)

  print "Index: "
  p index
  puts
  
  qi.read_messages(index) do |message|
    puts "From: #{message.from}"
    puts "To: #{message.to}"
    puts "Message body: "
    puts message.text
  end
  puts
end
