## insults courtesy of http://insulthost.colorado.edu/

PlugMan.define :insult do
  author "Mark Firestone"
  version "1.0.0"
  extends({ :main => [:bots] })
  requires []
  extension_points []
  params({ :description => "insult me|<person> | p => insult you or <person> p(rivmsg)", :cmd => "insult"})
	
	require "botplugins/support/common.rb"


@ADJ = [
"acidic",
"antique",
"contemptible",
"culturally-unsound",
"despicable",
"evil",
"fermented",
"festering",
"foul",
"fulminating",
"humid",
"impure",
"inept",
"inferior",
"industrial",
"left-over",
"low-quality",
"malodorous",
"off-color",
"penguin-molesting",
"petrified",
"pointy-nosed",
"salty",
"sausage-snorfling",
"tastless",
"tempestuous",
"tepid",
"tofu-nibbling",
"unintelligent",
"unoriginal",
"uninspiring",
"weasel-smelling",
"wretched",
"spam-sucking",
"egg-sucking",
"decayed",
"halfbaked",
"infected",
"squishy",
"porous",
"pickled",
"coughed-up",
"thick",
"vapid",
"hacked-up",
"unmuzzled",
"bawdy",
"vain",
"lumpish",
"churlish",
"fobbing",
"rank",
"craven",
"puking",
"jarring",
"fly-bitten",
"pox-marked",
"fen-sucked",
"spongy",
"droning",
"gleeking",
"warped",
"currish",
"milk-livered",
"surly",
"mammering",
"ill-borne",
"beef-witted",
"tickle-brained",
"half-faced",
"headless",
"wayward",
"rump-fed",
"onion-eyed",
"beslubbering",
"villainous",
"lewd-minded",
"cockered",
"full-gorged",
"rude-snouted",
"crook-pated",
"pribbling",
"dread-bolted",
"fool-born",
"puny",
"fawning",
"sheep-biting",
"dankish",
"goatish",
"weather-bitten",
"knotty-pated",
"malt-wormy",
"saucyspleened",
"motley-mind",
"it-fowling",
"vassal-willed",
"loggerheaded",
"clapper-clawed",
"frothy",
"ruttish",
"clouted",
"common-kissing",
"pignutted",
"folly-fallen",
"plume-plucked",
"flap-mouthed",
"swag-bellied",
"dizzy-eyed",
"gorbellied",
"weedy",
"reeky",
"measled",
"spur-galled",
"mangled",
"impertinent",
"bootless",
"toad-spotted",
"hasty-witted",
"horn-beat",
"yeasty",
"boil-brained",
"tottering",
"hedge-born",
"hugger-muggered",
"elf-skinned",
]

##
# Amounts 
##
@AMT= [
"accumulation",
"bucket",
"coagulation",
"enema-bucketful",
"gob",
"half-mouthful",
"heap",
"mass",
"mound",
"petrification",
"pile",
"puddle",
"stack",
"thimbleful",
"tongueful",
"ooze",
"quart",
"bag",
"plate",
"ass-full",
"assload",
]

##
# Objects
##
@NOUN = [
"bat toenails",
"bug spit",
"cat hair",
"chicken piss",
"dog vomit",
"dung",
"fat-woman's stomach-bile",
"fish heads",
"guano",
"gunk",
"pond scum",
"rat retch",
"red dye number-9",
"Sun IPC manuals",
"waffle-house grits",
"yoo-hoo",
"dog balls",
"seagull puke",
"cat bladders",
"pus",
"urine samples",
"squirrel guts",
"snake assholes",
"snake bait",
"buzzard gizzards",
"cat-hair-balls",
"rat-farts",
"pods",
"armadillo snouts",
"entrails",
"snake snot",
"eel ooze",
"slurpee-backwash",
"toxic waste",
"Stimpy-drool",
"poopy",
"poop",
"craptacular carpet droppings",
"jizzum",
"cold sores",
"anal warts",
]
  
	def parse(chell)
  
	instr = chell.split(' ')[1..-1].join(' ')
	
	deporter = /^(\S*)\s(.*)/  =~ instr
	cmd =instr
	param = nil
		if deporter then
			cmd = $1
			param = $2
		end
		cmd = "none" if cmd.nil?
		return [cmd,param]
  end
	
def do(m,options = {})
    suffix=""
   target,p = parse(m.params)
	 return["incorrect usage: " ,dest(m)] if target.strip == ""

    msgto = m.dest
     if(p)
      prefix = "you are "
      if (target =~ /^#/)
        prefix += "all "
      end
      msgto = target
      suffix = " (from #{m.sourcenick})"
    elsif(target =~ /^me$/)
      prefix = "you are "
    else
      who = target
      if (who == IRCBOTUSER)
        who = m.sourcenick
      end
      prefix = "#{who} is "
    end
    insult = generate_insult
    return [prefix + insult + suffix,msgto]
  end
	
  def generate_insult
    adj = @ADJ[rand(@ADJ.length)]
    adj2 = ""
    loop do
      adj2 = @ADJ[rand(@ADJ.length)]
      break if adj2 != adj
    end
    amt = @AMT[rand(@AMT.length)]
    noun = @NOUN[rand(@NOUN.length)]
    start = "a "
    start = "an " if ['a','e','i','o','u'].include?(adj[0].chr)
    "#{start}#{adj} #{amt} of #{adj2} #{noun}"
  end
end


