class Log
  attr_reader :filename

  def initialize(filename)
    @filename = filename
  end

  def rewrite!
    if File.exists?(filename) then
      lf = File.new(filename, File::TRUNC|File::RDWR, 0644)
      lf.close
    end
  end

  def write(line)
    File.open(filename, File::CREAT|File::APPEND|File::RDWR, 0644) do |lf|
      lf.puts line
    end
  end
end
