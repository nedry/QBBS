#-- vim:sw=2:et
#++
#
# :title: Weather plugin for rbot
#
# Author:: MrChucho (mrchucho@mrchucho.net): NOAA National Weather Service support
# Author:: Giuseppe "Oblomov" Bilotta <giuseppe.bilotta@gmail.com>
#
# Copyright:: (C) 2006 Ralph M. Churchill
# Copyright:: (C) 2006-2007 Giuseppe Bilotta
#
# License:: GPL v2
PlugMan.define :version do
  author "Giuseppe Bilotta"
  version "1.0.0"
  extends({ :main => [:bots] })
  requires []
  extension_points []
  params({ :description => "weather [<units>] <location> => display the current conditions at the location specified, looking it up on the Weather Underground site; you can use 'station <code>' to look up data by station code ( lookup your station code at http://www.weatherunderground.com/ ); you can optionally set <units>  to 'metric' or 'english' if you only want data with the units; use 'both' for units to go back to having both.\nweather nws <station> => display the current conditions at the location specified by the NOAA National Weather Service station code <station> ( lookup your station code at http://www.nws.noaa.gov/data/current_obs/ \n)", 
	                 :cmd => "weather"})
	
	require 'rexml/document'
	require "botplugins/support/common.rb"
	require 'rubygems'
  require 'excon'
	



    @wu_url   = "http://mobile.wunderground.com/cgi-bin/findweather/getForecast?brand=mobile%s&query=%s"
		@nws_url = "http://w1.weather.gov/xml/current_obs/%s.xml"

    @wu_station_url = "http://mobile.wunderground.com/auto/mobile%s/global/stations/%s.html"
		
		   def heat_index_or_wind_chill(cc)
        hi = cc[:heat_index_string]
        wc = cc[:windchill_string]
        if hi != 'NA' then
            " with a heat index of #{hi}"
        elsif wc != 'NA' then
            " with a windchill of #{wc}"
        else
            ""
        end
    end
		
	    def parse(cc_doc)
        cc = Hash.new
        cc_doc.elements.each do |c|
            cc[c.name.to_sym] = c.text
        end
        "At #{cc[:observation_time_rfc822]}, the wind was #{cc[:wind_string]} at #{cc[:location]} (#{cc[:station_id]}). The temperature was #{cc[:temperature_string]}#{heat_index_or_wind_chill(cc)}, and the pressure was #{cc[:pressure_string]}. The relative humidity was #{cc[:relative_humidity]}%. Current conditions are #{cc[:weather]} with #{cc[:visibility_mi]}mi visibility."
    end

   def nws_weather(m,where,debug,service)
        begin
				  response =Excon.get(@nws_url % [CGI.escape(where.upcase)])
					debug.push(@nws_url % [CGI.escape(where.upcase)])
			     feed= response.body
					 cc_doc = (REXML::Document.new feed).root
           result = parse(cc_doc)
					 @registry[m.sourcenick] = [service, where, ""]
						save_registry("weather")
           return result
        rescue  Exception  =>e
          return "Error retrieving data or station no found. #{e}"
					 end
		end

 def wu_weather(m, where, units,debug,service)
    begin
		response =Excon.get(@wu_url % [units, CGI.escape(where)])
		xml = response.body

      case xml
      when nil
        return  "couldn't retrieve weather information, sorry"
      when /City Not Found/
        return "no such location found (#{where})"
      when /Current<\/a>/
        data = ""
        xml.scan(/<table border.*?>(.*?)<\/table>/m).each do |match|
          data += wu_weather_filter(match.first)
        end
        if data.length > 0
					    @registry[m.sourcenick] = [service, where, units]
							save_registry("weather")
          return data
        else
          return "couldn't parse weather data from #{where}"
        end
        wu_out_special(m, xml)
      when /<a href="\/(?:global\/stations|US\/\w\w)\//
        wu_weather_multi(m, xml)
      else
      #  debug xml
        return "something went wrong with the data from #{where}..."
      end
	 rescue  Exception  =>e
          debug.push(e.backtrace)
          return  "retrieving info about '#{where}' failed (#{e})"
    end
  end
	
	 def wu_weather_filter(stuff)
    txt = wu_clean(stuff)

    result = Array.new
    if txt.match(/<\/a>\s*Updated:\s*(.*?)\s*Observed at\s*(.*?)\s*<\/td>/)
      result << ("Weather info for %s (updated on %s)" % [$2, $1])
    end
    txt.scan(/<tr>\s*<td>\s*(.*?)\s*<\/td>\s*<td>\s*(.*?)\s*<\/td>\s*<\/tr>/) { |k, v|
      next if v.empty?
      next if ["-", "- approx.", "N/A", "N/A approx."].include?(v)
      next if k == "Raw METAR"
      result << ("%s: %s" % [k, v])
    }
    return result.join(' -- ')
  end
	
	  def wu_clean(stuff)
    txt = stuff
    txt.gsub!(/[\n\s]+/,' ')
    txt.gsub!(/&nbsp;/, ' ')
    #txt.gsub!(/&#176;/, ' ') # degree sign
    txt.gsub!(/<\/?b>/,'')
    txt.gsub!(/<\/?span[^<>]*?>/,'')
    txt.gsub!(/<img\s*[^<>]*?>/,'')
    txt.gsub!(/<br\s?\/?>/,'')
    txt.gsub!("&deg;",176.chr) # put the degree sign back in.
  end
	
def do(m,options = {})
    load_("weather")
		
	instr = m.params.to_s
	param =""
	happy = /^\!(\S*)\s(.*)/ =~ instr
	param = $2.downcase if happy
	loc = ""
	
    if param.empty?
      if @registry.has_key?(m.sourcenick)
        where = @registry[m.sourcenick]
   #     debug "Loaded weather info #{where.inspect} for #{m.sourcenick}"

        service = where.first.to_sym
        loc = where[1].to_s
        units = params[:units] || where[2] rescue nil
      else
        options[:debuglog].push( "No weather info for #{m.sourcenick}")
        return ["I don't know where you are yet, #{m.sourcenick}. Request a specific station and I will remember it.",dest(m)]

      end
    else
      where = param.split(" ")
      if ['nws','station'].include?(where.first)
        service = where.first.to_sym
        loc = where[1].to_s
      else
        service = :wu
        loc = where[0].to_s
      end
      units = params[:units]
    end

    if loc.empty?
     # debug "No weather location found for #{m.sourcenick}"
      return[ "I don't know where you are yet, #{m.sourcenick}. See 'help weather nws' or 'help weather wu' for additional help",dest(m)]
    end

    wu_units = String.new
    if units
      case units.to_sym
      when :english, :metric
       # wu_units = "_#{units}"
      when :both
      else
        options[:debuglog].push( "Ignoring unknown units #{units}")
        wu_units = String.new
      end
    end

    case service
    when :nws
      out = nws_weather(m,loc,options[:debuglog],service)
			return [out,dest(m)]
    when :station
      wu_station(m, loc, wu_units)
    when :wu
      out = wu_weather(m, loc, wu_units,options[:debuglog],service)
			return [out,dest(m)]
    end


  end
	end

  
	


 



#plugin.map 'weather :units *where', :defaults => {:where => false, :units => false}, :requirements => {:units => /metric|english|both/}
