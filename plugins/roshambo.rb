# Play the game of roshambo (rock-paper-scissors)
# Copyright (C) 2004 Hans Fugal
# Distributed under the same license as rbot itself
#
# Modified to play like The Big Bang Theory with Spock-Lizard
# and to be a bit less turse by Mark Firestone
#
require 'time'
class RoshamboPlugin < Plugin
  def initialize
    super 
    @scoreboard = {}
  end
  def help(plugin, topic="")
    "roshambo <rock|paper|scissors|lizard|Spock> => play roshambo"
  end
  def privmsg(m)
    # simultaneity
    choice = choose

    # init scoreboard
    if (not @scoreboard.has_key?(m.sourcenick) or (Time.now - @scoreboard[m.sourcenick]['timestamp']) > 3600)
      @scoreboard[m.sourcenick] = {'me'=>0,'you'=>0,'timestamp'=>Time.now}
    end
    case m.params
    when 'rock','paper','scissors','lizard','spock'
      comp_choice = choice
      rep,s = verb(comp_choice,m.params.downcase)
      @scoreboard[m.sourcenick]['timestamp'] = Time.now
      myscore=@scoreboard[m.sourcenick]['me']
      yourscore=@scoreboard[m.sourcenick]['you']
      case s
      when 1
	yourscore=@scoreboard[m.sourcenick]['you'] += 1
	m.reply ("%{highlight}#{comp_choice}!%{highlight}   #{rep}!   You win.   Score..   Me: #{myscore}   You: #{yourscore}" % {:highlight => Bold })
      when 0
	m.reply ("%{highlight}#{comp_choice}!%{highlight}   #{rep}.   We tie.   Score...   Me: #{myscore}   You: #{yourscore}" % {:highlight => Bold })
      when -1
	myscore=@scoreboard[m.sourcenick]['me'] += 1
	m.reply ("%{highlight}#{comp_choice}!%{highlight}   #{rep}!   I win!   Score...   Me: #{myscore}   You: #{yourscore}" % {:highlight => Bold })
      end
    else
      m.reply "incorrect usage: " + help(m.plugin)
    end
  end
      
  def verb(a,b)
    test = "#{a} #{b}"
    case test
       when "paper rock"
         return ["Paper %{highlight}covers%{highlight} rock",-1]
        when "rock lizard"
         return ["Rock %{highlight}crushes%{highlight} lizard",-1]
        when "lizard spock"
         return ["Lizard %{highlight}poisons%{highlight} Spock",-1]
        when "spock scissors"
         return ["Spock %{highlight}crushes%{highlight} scissors",-1]
        when "scissors lizard"
         return ["Scissors %{highlight}decapitates%{highlight} lizard",-1]
        when "lizard paper"
         return ["Lizard %{highlight}eats%{highlight} paper",-1]
        when "paper spock"
         return ["Paper %{highlight}disproves%{highlight} Spock",-1]
        when "spock rock"
         return ["Spock %{highlight}vaporises%{highlight} rock",-1]
        when "rock scissors"
         return ["Rock %{highlight}crushes%{highlight} scissors",-1]

        when "rock paper"
       return ["Paper %{highlight}covers%{highlight} rock",1]
        when "lizard rock"
         return ["Rock %{highlight}crushes%{highlight} lizard",1]
        when "spock lizard"
         return ["Lizard %{highlight}poisons%{highlight} Spock",1]
        when "scissors spock"
         return ["Spock %{highlight}crushes%{highlight} scissors",1]
        when "lizard scissors"
         return ["Scissors %{highlight}decapitates%{highlight} lizard",1]
        when "paper lizard"
         return ["Lizard %{highlight}eats%{highlight} paper",1]
        when "spock paper"
         return ["Paper %{highlight}disproves%{highlight} Spock",1]
        when "rock spock"
         return ["Spock %{highlight}vaporises%{highlight} rock",1]
        when "scissors rock"
         return ["Rock %{highlight}crushes%{highlight} scissors",1]
       end
       return ["#{a} %{highlight}ties%{highlight} #{b}",0]
     end
     
  def choose
    ['rock','paper','scissors','lizard','spock'][rand(5)]
  end
end
plugin = RoshamboPlugin.new
plugin.register("roshambo")
plugin.register("rps")
