	def dest(m)
	  dest = m.dest
    dest = m.sourcenick if m.dest == IRCBOTUSER
	end
	

	def load_registry(plugin)
	 @registry={}
	  if File.exists?("botplugins/data/#{plugin}")
	    File.open("botplugins/data/#{plugin}") do |f|  
        @registry= Marshal.load(f) 
		  end
	end
end
	
def save_registry(plugin)
  File.open("botplugins/data/#{plugin}", 'w+') do |f|  
    Marshal.dump(@registry, f)
  end		
end

		def safe_exec(command, *args)
      IO.popen("-") {|p|
        if(p)
          return p.readlines.join("\n")
        else
          begin
            $stderr = $stdout
            exec(command, *args)
          rescue Exception => e
            puts "exec of #{command} led to exception: #{e.inspect}"
            Kernel::exit! 0
          end
          puts "exec of #{command} failed"
          Kernel::exit! 0
        end
      }
    end

   def http_get(uristr, readtimeout=8, opentimeout=4)

      # ruby 1.7 or better needed for this (or 1.6 and debian unstable)
      Net::HTTP.version_1_2
      # (so we support the 1_1 api anyway, avoids problems)

      uri = URI.parse uristr
      query = uri.path
      if uri.query
        query += "?#{uri.query}"
      end

      proxy_host = nil
      proxy_port = nil
      if(ENV['http_proxy'] && proxy_uri = URI.parse(ENV['http_proxy']))
        proxy_host = proxy_uri.host
        proxy_port = proxy_uri.port
      end

      begin
        http = Net::HTTP.new(uri.host, uri.port, proxy_host, proxy_port)
        http.open_timeout = opentimeout
        http.read_timeout = readtimeout

        http.start {|http|
          resp = http.get(query)
          if resp.code == "200"
            return resp.body
          end
        }
      rescue => e
        # cheesy for now
        error "Utils.http_get exception: #{e.inspect}, while trying to get #{uristr}"
        return nil
      end
    end