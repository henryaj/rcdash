class Mac
  MAC_ADDRESS_REGEX = /^((([a-fA-F0-9][a-fA-F0-9]+[:]){5})([a-fA-F0-9][a-fA-F0-9])$)|(^([a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9]+[.]){2}([a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9]))$/

  def self.valid?(str)
    result = MAC_ADDRESS_REGEX.match(str)
    result ? true : false
  end

  def self.normalize(str)
    str.gsub("-", ":")
  end
end