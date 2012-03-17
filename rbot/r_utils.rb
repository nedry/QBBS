# encoding: utf-8
require 'net/http'
require 'uri'

#module Irc

  # miscellaneous useful functions
  module Utils

  UNESCAPE_TABLE = {
    'laquo' => '«',
    'raquo' => '»',
    'quot' => '"',
    'apos' => '\'',
    'micro' => 'µ',
    'copy' => '©',
    'trade' => '™',
    'reg' => '®',
    'amp' => '&',
    'lt' => '<',
    'gt' => '>',
    'hellip' => '…',
    'nbsp' => ' ',
    'Agrave' => 'À',
    'Aacute' => 'Á',
    'Acirc' => 'Â',
    'Atilde' => 'Ã',
    'Auml' => 'Ä',
    'Aring' => 'Å',
    'AElig' => 'Æ',
    'OElig' => 'Œ',
    'Ccedil' => 'Ç',
    'Egrave' => 'È',
    'Eacute' => 'É',
    'Ecirc' => 'Ê',
    'Euml' => 'Ë',
    'Igrave' => 'Ì',
    'Iacute' => 'Í',
    'Icirc' => 'Î',
    'Iuml' => 'Ï',
    'ETH' => 'Ð',
    'Ntilde' => 'Ñ',
    'Ograve' => 'Ò',
    'Oacute' => 'Ó',
    'Ocirc' => 'Ô',
    'Otilde' => 'Õ',
    'Ouml' => 'Ö',
    'Oslash' => 'Ø',
    'Ugrave' => 'Ù',
    'Uacute' => 'Ú',
    'Ucirc' => 'Û',
    'Uuml' => 'Ü',
    'Yacute' => 'Ý',
    'THORN' => 'Þ',
    'szlig' => 'ß',
    'agrave' => 'à',
    'aacute' => 'á',
    'acirc' => 'â',
    'atilde' => 'ã',
    'auml' => 'ä',
    'aring' => 'å',
    'aelig' => 'æ',
    'oelig' => 'œ',
    'ccedil' => 'ç',
    'egrave' => 'è',
    'eacute' => 'é',
    'ecirc' => 'ê',
    'euml' => 'ë',
    'igrave' => 'ì',
    'iacute' => 'í',
    'icirc' => 'î',
    'iuml' => 'ï',
    'eth' => 'ð',
    'ntilde' => 'ñ',
    'ograve' => 'ò',
    'oacute' => 'ó',
    'ocirc' => 'ô',
    'otilde' => 'õ',
    'ouml' => 'ö',
    'oslash' => 'ø',
    'ugrave' => 'ù',
    'uacute' => 'ú',
    'ucirc' => 'û',
    'uuml' => 'ü',
    'yacute' => 'ý',
    'thorn' => 'þ',
    'yuml' => 'ÿ'
        }
        
    def Utils.decode_html_entities(str)
      if defined? ::HTMLEntities
        return HTMLEntities.decode_entities(str)
      else
        str.gsub(/(&(.+?);)/) {
          symbol = $2
          # remove the 0-paddng from unicode integers
          if symbol =~ /^#(\d+)$/
            symbol = $1.to_i.to_s
          end

          # output the symbol's irc-translated character, or a * if it's unknown
          UNESCAPE_TABLE[symbol] || (symbol.match(/^\d+$/) ? [symbol.to_i].pack("U") : '*')
        }
      end
    end
    
    # turn a number of seconds into a human readable string, e.g
    # 2 days, 3 hours, 18 minutes, 10 seconds
    def Utils.secs_to_string(secs)
      ret = ""
      days = (secs / (60 * 60 * 24)).to_i
      secs = secs % (60 * 60 * 24)
      hours = (secs / (60 * 60)).to_i
      secs = (secs % (60 * 60))
      mins = (secs / 60).to_i
      secs = (secs % 60).to_i
      ret += "#{days} days, " if days > 0
      ret += "#{hours} hours, " if hours > 0 || days > 0
      ret += "#{mins} minutes and " if mins > 0 || hours > 0 || days > 0
      ret += "#{secs} seconds"
      return ret
    end


    def Utils.safe_exec(command, *args)
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

    # returns a string containing the result of an HTTP GET on the uri
    def Utils.http_get(uristr, readtimeout=8, opentimeout=4)

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
  end
#end
