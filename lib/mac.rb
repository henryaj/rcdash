require 'digest'

class Mac
  # Matches all MAC addresses of the format xx-xx-xx-xx-xx-xx or xx:xx:xx:xx:xx:xx
  # where 'xx' is a hex byte.
  MAC_ADDRESS_REGEX = /^((([a-fA-F0-9][a-fA-F0-9]+[:]){5})([a-fA-F0-9][a-fA-F0-9])$)|(^([a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9]+[.]){2}([a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9]))$/

  def self.valid?(str)
    !!MAC_ADDRESS_REGEX.match(str)
  end

  def self.normalize(str)
    str.gsub("-", ":")
  end

  def self.hash(str)
    salted = str + ENV.fetch("SALT")
    Digest::SHA256.base64digest(salted)
  end
end