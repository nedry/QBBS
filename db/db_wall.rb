require 'models/wall'

def add_wall(uid,message,l_type)

  entry = Wall.create(
	:number => uid,
	:timeposted => Time.now,
	:message => message,
	:l_type => l_type)
end
	
def fetch_wall
  Wall.all(:order => [:timeposted.desc])
end

def wall_cull
  chellie_deporters_head = Wall.all(:order => [:timeposted.desc])
   for i in 0..chellie_deporters_head.length - 1
    chellie_deporters_head[i].destroy!  if i > 10
  end
  
end

def wall_empty
  Wall.count == 0
end
