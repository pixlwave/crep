class String

  @@formatter = NSNumberFormatter.new
  @@formatter.numberStyle = NSNumberFormatterSpellOutStyle

  def as_number
    num = self.to_i                               # convert to int
    unless num > 0 || num.to_s == self            # if not a valid number try again
      num = @@formatter.numberFromString(self)    # returns nil if not a valid number
    end

    num                                           # return number or nil
  end

end