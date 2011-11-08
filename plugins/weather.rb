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

require 'rexml/document'


# Wraps NOAA National Weather Service information
class CurrentConditions
    def initialize(station)
        @station = station
        @url = "http://www.nws.noaa.gov/data/current_obs/#{@station.upcase}.xml"
        @etag = String.new
        @mtime = Time.mktime(0)
        @current_conditions = String.new
        @iscached = false
    end
    def update
        begin
            open(@url,"If-Modified-Since" => @mtime.rfc2822) do |feed|
            # open(@url,"If-None-Match"=>@etag) do |feed|
                @etag = feed.meta['etag']
                @mtime = feed.last_modified
                cc_doc = (REXML::Document.new feed).root
                @iscached = false
                @current_conditions = parse(cc_doc)
            end
        rescue OpenURI::HTTPError => e
            case e
            when /304/
                @iscached = true
            when /404/
                raise "Data for #{@station} not found"
            else
                raise "Error retrieving data: #{e}"
            end
        end
        @current_conditions # +" Cached? "+ ((@iscached) ? "Y" : "N")
    end
    def parse(cc_doc)
        cc = Hash.new
        cc_doc.elements.each do |c|
            cc[c.name.to_sym] = c.text
        end
        "At #{cc[:observation_time_rfc822]}, the wind was #{cc[:wind_string]} at #{cc[:location]} (#{cc[:station_id]}). The temperature was #{cc[:temperature_string]}#{heat_index_or_wind_chill(cc)}, and the pressure was #{cc[:pressure_string]}. The relative humidity was #{cc[:relative_humidity]}%. Current conditions are #{cc[:weather]} with #{cc[:visibility_mi]}mi visibility."
    end
private
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
end

class WeatherPlugin < Plugin

  Config.register Config::BooleanValue.new('weather.advisory',
    :default => true,
    :desc => "Should the bot report special weather advisories when any is present?")

  def help(plugin, topic="")
    case topic
    when "nws"
      "weather nws <station> => display the current conditions at the location specified by the NOAA National Weather Service station code <station> ( lookup your station code at http://www.nws.noaa.gov/data/current_obs/ )"
    when "station", "wu"
      "weather [<units>] <location> => display the current conditions at the location specified, looking it up on the Weather Underground site; you can use 'station <code>' to look up data by station code ( lookup your station code at http://www.weatherunderground.com/ ); you can optionally set <units>  to 'metric' or 'english' if you only want data with the units; use 'both' for units to go back to having both."
    else
      "weather information lookup. Looks up weather information for the last location you specified. See topics 'nws' and 'wu' for more information"
    end
  end

  def initialize
    super

    @nws_cache = Hash.new

    @wu_url         = "http://mobile.wunderground.com/cgi-bin/findweather/getForecast?brand=mobile%s&query=%s"
    @wu_station_url = "http://mobile.wunderground.com/auto/mobile%s/global/stations/%s.html"
  end

  def weather(m, params)
    if params[:where].empty?
      if @registry.has_key?(m.sourcenick)
        where = @registry[m.sourcenick]
        debug "Loaded weather info #{where.inspect} for #{m.sourcenick}"

        service = where.first.to_sym
        loc = where[1].to_s
        units = params[:units] || where[2] rescue nil
      else
        debug "No weather info for #{m.sourcenick}"
        m.reply "I don't know where you are yet, #{m.sourcenick}. See 'help weather nws' or 'help weather wu' for additional help"
        return
      end
    else
      where = params[:where]
      if ['nws','station'].include?(where.first)
        service = where.first.to_sym
        loc = where[1].to_s
      else
        service = :wu
        loc = where.to_s
      end
      units = params[:units]
    end

    if loc.empty?
      debug "No weather location found for #{m.sourcenick}"
      m.reply "I don't know where you are yet, #{m.sourcenick}. See 'help weather nws' or 'help weather wu' for additional help"
      return
    end

    wu_units = String.new
    if units
      case units.to_sym
      when :english, :metric
        wu_units = "_#{units}"
      when :both
      else
        m.reply "Ignoring unknown units #{units}"
        wu_units = String.new
      end
    end

    case service
    when :nws
      nws_describe(m, loc)
    when :station
      wu_station(m, loc, wu_units)
    when :wu
      wu_weather(m, loc, wu_units)
    end

    @registry[m.sourcenick] = [service, loc, units]
  end

  def nws_describe(m, where)
    if @nws_cache.has_key?(where) then
        met = @nws_cache[where]
    else
        met = CurrentConditions.new(where)
    end
    if met
      begin
        m.reply met.update
        @nws_cache[where] = met
      rescue => e
        m.reply e.message
      end
    else
      m.reply "couldn't find weather data for #{where}"
    end
  end

  def wu_station(m, where, units)
    begin
      xml = @bot.httputil.get(@wu_station_url % [units, CGI.escape(where)])
      case xml
      when nil
        m.reply "couldn't retrieve weather information, sorry"
        return
      when /Search not found:/
        m.reply "no such station found (#{where})"
        return
      when /<table border.*?>(.*?)<\/table>/m
        data = $1.dup
        m.reply wu_weather_filter(data)
        wu_out_special(m, xml)
      else
        debug xml
        m.reply "something went wrong with the data for #{where}..."
      end

    rescue Exception => e
   #   m.reply "retrieving info about '#{where}' failed (#{e})"
      m.reply e.backtrace.map { |x| x.match(/^(.+?):(\d+)(|:in `(.+)')$/);
      [$1,$2,$3]}
    end
  end

  def wu_weather(m, where, units)
    begin
      xml = @bot.httputil.get(@wu_url % [units, CGI.escape(where)])
      case xml
      when nil
        m.reply "couldn't retrieve weather information, sorry"
      when /City Not Found/
        m.reply "no such location found (#{where})"
      when /Current<\/a>/
        data = ""
        xml.scan(/<table border.*?>(.*?)<\/table>/m).each do |match|
          data += wu_weather_filter(match.first)
        end
        if data.length > 0
          m.reply data
        else
          m.reply "couldn't parse weather data from #{where}"
        end
        wu_out_special(m, xml)
      when /<a href="\/(?:global\/stations|US\/\w\w)\//
        wu_weather_multi(m, xml)
      else
        debug xml
        m.reply "something went wrong with the data from #{where}..."
      end
    rescue  Exception  =>e
          m.reply e.backtrace.map { |x| x.match(/^(.+?):(\d+)(|:in `(.+)')$/);
      [$1,$2,$3]}
      m.reply "retrieving info about '#{where}' failed (#{e})"
    end
  end

  def wu_clean(stuff)
    txt = stuff
    txt.gsub!(/[\n\s]+/,' ')
    txt.gsub!(/&nbsp;/, ' ')
    txt.gsub!(/&#176;/, ' ') # degree sign
    txt.gsub!(/<\/?b>/,'')
    txt.gsub!(/<\/?span[^<>]*?>/,'')
    txt.gsub!(/<img\s*[^<>]*?>/,'')
    txt.gsub!(/<br\s?\/?>/,'')
    txt
  end

  def wu_weather_multi(m, xml)
    # debug xml
    stations = xml.scan(/<td>\s*(?:<a href="([^?"]+\?feature=[^"]+)"\s*[^>]*><img [^>]+><\/a>\s*)?<a href="\/(?:global\/stations|US\/(\w\w))\/([^"]*?)\.html">(.*?)<\/a>\s*:\s*(.*?)<\/td>/m)
    # debug stations
    m.reply "multiple stations available, use 'weather station <code>' or 'weather <city, state>' as appropriate, for one of the following (current temp shown):"
    stations.map! { |ar|
      warning = ar[0]
      loc = ar[2]
      state = ar[1]
      par = ar[3]
      w = ar[4]
      if state # US station
        (warning ? "*" : "") + ("%s, %s (%s): %s" % [loc, state, par, wu_clean(w)])
      else # non-US station
        (warning ? "*" : "") + ("station %s (%s): %s" % [loc, par, wu_clean(w)])
      end
    }
    m.reply stations.join("; ")
  end

  def wu_check_special(xml)
    specials = []
    # We only scan the first half to prevent getting the advisories twice
    xml[0,xml.length/2].scan(%r{<a href="([^"]+\?[^"]*feature=warning#([^"]+))"[^>]*>([^<]+)</a>}) do
      special = {
        :url => "http://mobile.wunderground.com"+$1,
        :type => $2.dup,
        :special => $3.dup
      }
      spec_rx = Regexp.new("<a name=\"#{special[:type]}\">(?:.+?)<td align=\"left\">\\s+(.+?)\\s+</td>\\s+</tr>\\s+</table>", Regexp::MULTILINE)
      spec_xml = @bot.httputil.get(special[:url])
      if spec_xml and spec_td = spec_xml.match(spec_rx)
        special.merge!(:text => spec_td.captures.first.ircify_html)
      end
      specials << special
    end
    return specials
  end

  def wu_out_special(m, xml)
    return unless @bot.config['weather.advisory']
    specials = wu_check_special(xml)
    debug specials
    specials.each do |special|
      special.merge!(:underline => Underline)
      if special[:text]
        m.reply("%{underline}%{special}%{underline}: %{text}" % special)
      else
        m.reply("%{underline}%{special}%{underline} @ %{url}" % special)
      end
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
    return result.join('; ')
  end
end

plugin = WeatherPlugin.new
plugin.map 'weather :units *where', :defaults => {:where => false, :units => false}, :requirements => {:units => /metric|english|both/}
