def parse_intl(address)
  happy = (/^(\d?):(\d{1,4})\/(.*)/) =~ address
  if happy then
    zone = $1;net = $2;node = $3
    grumpy = (/(\d{1,4})\.(\d{1,4})/) =~ node
    if grumpy then
      node = $1;point = $2
    end
  end
  return [zone,net,node,point]
end

def time_thingie(time)
  out = "th"

  case time.strftime("%-d")
  when "1"; out = "st"
  when "2"; out = "nd"
  when "3"; out = "rd"
  end
  return out
end

def default(inp, d)
  (yield inp) ? inp : d
end

def nilv(inp, d)
  default(inp, d) {|i| !i.nil?}
end

def emptyv(inp, d)
  default(inp, d) {|i| !i.empty?}
end

def zerov(inp, d)
  default(inp, d) {|i| i == 0}
end

class String
  def integer?
    self =~ /^[+-]?\d+/
  end

  def empty?
    self == ""
  end

  def stripcolor
    a = dup
    COLORTABLE.each_key {|color| a.gsub!(color, '')}
    a
  end

  def fit(n)
    m = n + (self.length - self.stripcolor.length)
    self.slice(0..(m-1)).ljust(m)
  end
end

class Array
  def empty?
    length == 0
  end

  def has_index?(i)
    (0..(length-1)).include?(i)
  end

  def formatrow(widths)
    map.with_index {|a,i| (a.to_s).fit(widths[i])}.join
  end
end
