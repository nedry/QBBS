class String

  def is_date?
    temp = self.gsub(/[-.\/]/, '')
    ['%m%d%Y','%m%d%y','%M%D%Y','%M%D%y'].each do |f|
      begin
        return true if Date.strptime(temp, f)
      rescue
        #do nothing
      end
    end

    return false
  end
end


class Session
  def pick_one(sequence)
    sequence[rand(sequence.length)]
  end

  def timeofday
    hour = Time.now.hour
    timeofday = (
    case hour
    when 0..11; "Morning"
    when 12..17; "Afternoon"
    when 17..24; "Evening"
    end
    )
  end
end



def disk_used_space( path )
  `df -Pk #{path} |grep ^/ | awk '{print $3;}'`.to_i * 1024
end

def disk_free_space( path )
  `df -Pk #{path} |grep ^/ | awk '{print $4;}'`.to_i * 1024
end

def disk_total_space( path )
  `df -Pk #{path} |grep ^/ | awk '{print $2;}'`.to_i * 1024
end

def disk_percent_free( path )
  `df -Pk #{path} |grep ^/ | awk '{print $5;}'`.chop!.to_i

end
