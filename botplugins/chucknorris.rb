PlugMan.define :chucknorris do
  author "Mark Firestone"
  version "1.0.0"
  extends({ :main => [:bots] })
  requires []
  extension_points []
  params({ :description => "chucknorris [min_rating] => \"fact\" shows a random Chuck Norris fact (optional minimum rating from 1-10, default=6.0).", :cmd => "chucknorris"})
	
	require "botplugins/support/common.rb"

require 'yaml'
require 'zlib'

MIN_RATING = 6.0
MIN_VOTES = 25




  def name
    "chucknorris"
  end
  
  # Just a little helper for the initialize method...
  def find_facts_file(name)
    full_path = File.join "botplugins", name
    found_files = Dir[full_path]
    if found_files.empty?
      nil
    else
      found_files[0]
    end
  end
  

  # The meat.
def do(m,options={})
	
	instr = m.params.to_s
	param =""
	happy = /^\!(\S*)\s(.*)/ =~ instr
	param = $2.downcase if happy
	loc = ""

if path = find_facts_file('chucknorris.yml')
      fyml = open(path)
	else
      return [ "Error: Couldn't find chucknorris.yml",dest(m)]
	end
    
    @@facts = YAML.load(fyml).map{|fact,(score,votes)| votes >= MIN_VOTES ? [score,fact] : nil}.compact


    min = MIN_RATING.to_f 
		min = param.to_f if !param.nil?
    viable_facts = @@facts.select {|rating, fact| rating >= min}
    return ["Are you nuts?!? There are no facts better than #{min}!!!",nil]  if viable_facts.empty?

    rating, fact = viable_facts[rand(viable_facts.length)]

    return ["#{fact} [score=#{rating}]",dest(m)]
  end

end



