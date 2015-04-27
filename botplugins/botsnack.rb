#-- vim:sw=2:et
#++
#
# :title: botsnack - give your bot some love
# :version: 1.0a
#
# Author:: Jan Wikholm <jw@jw.fi>
#
# Copyright:: (C) 2008 Jan Wikholm
#
# License:: public domain
#
# TODO More replies


PlugMan.define :botsnack do
  author "Jan Wikholm"
  version "1.0.0"
  extends({ :main => [:bots] })
  requires []
  extension_points []
  params({ :description => "botsnack => reward HAL for being good", :cmd => "botsnack"})
	
	require "botplugins/support/common.rb"

@THANKS = ["thanks :)","schweet!","ta :)","=D","cheers!"]
@THANKS_X =["%s: thanks :)", "%s: schweet!","%s: =D","%s: ta :)","%s: cheers"]


  def do(m,options ={})
    if m.dest == IRCCHANNEL
      return ["#{@THANKS_X[rand(@THANKS_X.length)]}" % m.sourcenick,dest(m)]
    else
      return ["#{@THANKS[rand(@THANKS.length)]}",dest(m)]
    end
  end
end


