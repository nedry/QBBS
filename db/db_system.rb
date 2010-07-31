require 'models/system'
def update_system(r)
 r.save
end

def fetch_system
  System.first(:rec => 1)
end

