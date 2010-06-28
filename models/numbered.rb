# Class methods common to models that have a `number` field

module Numbered
  def renumber!
    n = 1
    self.all(:order => :number).each do |b|
      b.update(:number => n)
      n = n + 1
    end
  end

  def delete_number(n)
    x = self.first(:number => n)
    x.destroy! if x
  end
end
