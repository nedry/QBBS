
$LOAD_PATH << "."
require 'fsed'
require "tools.rb"
#require "raspell"



SPELL_CHECK = true     #if you don't want raspell, comment out the require above.

COLORTABLE = {
  '%R' => "\e[;1;31;44m", '%G' => "\e[;1;32;44m",
  '%Y' => "\e[;1;33;44m", '%B' => "\e[;1;34;44m",
  '%M' => "\e[;1;35;44m", '%C' => "\e[;1;36;44m",
  '%W' => "\e[;1;37;44m", '%r' => "\e[;31;44m",
  '%g' => "\e[;32;44m", '%y' => "\e[;33;44m",
  '%b' => "\e[;34;44m", '%m' => "\e[;35;44m",
  '%c' => "\e[;36;44m", '%w' => "\e[;31;44m"
}

REDRAW = true
NO_REDRAW = false

def tcgetattr(io)
  _TCGETA = 0x5405
  attr = [0, 0, 0, 0].pack("SSSS")
  io.ioctl(_TCGETA, attr)
  attr
end

def tcsetattr(io, attr)
  _TCSETA = 0x5406
  io.ioctl(_TCSETA, attr)
end

def writefile(filename, array)
  return unless filename
  lf = File.new(filename, File::WRONLY|File::TRUNC|File::CREAT, 0644)
  array.each {|x|
    lf.puts x
  }
  lf.close
  puts
end

	
def pull_apart_args(args)
  bbs_mode = false
  filename = nil
  if !args.nil? then
    filename = args.last
    args.each {|arg|
      bbs_mode = true if arg == "-L"
      #put more switches here
    }
  end
  return [bbs_mode,filename]
end

begin

  unless RUBY_PLATFORM =~ /mswin32/
    # turn off stdin buffering and echo

    # c_iflag bits
    INLCR  = "0000100".to_i
    IGNCR  = "0000200".to_i
    ICRNL  = "0000400".to_i

    # c_oflag bits
    OPOST  = "0000001".to_i

    # c_lflag bits
    ISIG   = "0000001".to_i
    ICANON = "0000002".to_i
    ECHO   = "0000010".to_i

    old_attr = tcgetattr($stdin)
    input, output, control, local = old_attr.unpack("SSSS")
    # input &= ~(INLCR | IGNCR | ICRNL)
    # output &= ~OPOST
    #local &= ~(ECHO | ICANON | ISIG)
    local &= ~(ECHO)
    new_attr = [input, output, control, local].pack("SSSS")
    tcsetattr($stdin, new_attr)
  end

  bbs_mode,in_file = pull_apart_args(ARGV)
  sleep(2)
  editor = Editors::FSED::Editor.new(80, 23, STDIN.to_io, $>.to_io,in_file,bbs_mode)

  buffer = editor.run
  # if bbs_mode then
  $lf.print "writing file...\n"
  writefile(in_file,buffer.buff_out)
  $lf.print "file written...\n"
  #end
ensure
  unless RUBY_PLATFORM =~ /mswin32/
    tcsetattr($stdin, old_attr)
  end
end

