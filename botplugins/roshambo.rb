# Play the game of roshambo (rock-paper-scissors)
# Copyright (C) 2004 Hans Fugal
# Distributed under the same license as rbot itself
#
# Modified to play like The Big Bang Theory version with Spock-Lizard, 
# to be a bit less turse and converted to QBBS by Mark Firestone
#

PlugMan.define :roshambo do
  author "Hans Fugal"
  version "1.0.0"
  extends({ :main => [:bots] })
  requires []
  extension_points []
  params({ :description => "roshambo <rock|paper|scissors|lizard|Spock> => play roshambo", :cmd => "roshambo"})
	
require "botplugins/support/common.rb"

def load_scoreboard
	 @scoreboard ={}
	  if File.exists?('botplugins/data/roshambo')
	    File.open('botplugins/data/roshambo') do |f|  
        @scoreboard = Marshal.load(f) 
		  end
	end
end
	
def save_scoreboard
  File.open('botplugins/data/roshambo', 'w+') do |f|  
    Marshal.dump(@scoreboard, f)
  end		
end

  def choose
    ['rock','paper','scissors','lizard','spock'][rand(5)]
  end
	
  def verb(a,b)
    test = "#{a} #{b}"
    case test
       when "paper rock"
         return ["Paper covers rock",-1]
        when "rock lizard"
         return ["Rock crushes lizard",-1]
        when "lizard spock"
         return ["Lizard poisons Spock",-1]
        when "spock scissors"
         return ["Spock crushes scissors",-1]
        when "scissors lizard"
         return ["Scissors decapitates lizard",-1]
        when "lizard paper"
         return ["Lizard eats paper",-1]
        when "paper spock"
         return ["Paper disproves Spock",-1]
        when "spock rock"
         return ["Spock vaporises rock",-1]
        when "rock scissors"
         return ["Rock crushes scissors",-1]

        when "rock paper"
       return ["Paper covers rock",1]
        when "lizard rock"
         return ["Rock crushes lizard",1]
        when "spock lizard"
         return ["Lizard poisons Spock",1]
        when "scissors spock"
         return ["Spock crushes scissors",1]
        when "lizard scissors"
         return ["Scissors decapitates lizard",1]
        when "paper lizard"
         return ["Lizard eats paper",1]
        when "spock paper"
         return ["Paper disproves Spock",1]
        when "rock spock"
         return ["Spock vaporises rock",1]
        when "scissors rock"
         return ["Rock crushes scissors",1]
       end
       return ["#{a} ties #{b}",0]
     end
		 
		 

def do(m,options = {})
	   choice = choose

    # init scoreboard
		load_scoreboard
    if (not @scoreboard.has_key?(m.sourcenick) or (Time.now - @scoreboard[m.sourcenick]['timestamp']) > 3600)
      @scoreboard[m.sourcenick] = {'me'=>0,'you'=>0,'timestamp'=>Time.now}
    end
	

	
	instr = m.params.to_s
	param =""
	happy = /^\!(\S*)\s(.*)/ =~ instr
	param = $2.downcase if happy
	
    case param
    when 'rock','paper','scissors','lizard','spock'
      comp_choice = choice
      rep,s = verb(comp_choice,param)
      @scoreboard[m.sourcenick]['timestamp'] = Time.now
      myscore=@scoreboard[m.sourcenick]['me']
      yourscore=@scoreboard[m.sourcenick]['you']
      case s
      when 1
	yourscore=@scoreboard[m.sourcenick]['you'] += 1
	out = ("#{comp_choice}! #{rep}! You win.  Score: Me: #{myscore} You: #{yourscore}" )
      when 0
	out = ("#{comp_choice}! #{rep}. We tie.   Score: Me: #{myscore} You: #{yourscore}" )
      when -1
	myscore=@scoreboard[m.sourcenick]['me'] += 1
	out = ("#{comp_choice}! #{rep}! I win!   Score: Me: #{myscore} You: #{yourscore}" )
      end
    else
      out = "incorrect usage: type !help roshambo"
    end
		save_scoreboard
		return  [out,dest(m)]
  end
	
  

end
