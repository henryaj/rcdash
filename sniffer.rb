require 'pty'

class Sniffer
  def self.start_network_sniffing
    PTY.spawn( "tshark -Tfields -e eth.addr" ) do |stdout, _, _|
      begin
        stdout.each do |line|
          puts "hi"
          next if line.include?("Capturing")
          mac = line.split(",").last.strip
          record_user_seen(mac)
        end
      rescue Exception => e
        puts e
      end
    end
  end

  def self.record_user_seen(mac)
    u = User.where(mac: mac)
    if u.any?
      puts "boom"
      u.first.seen!
    end
  end
end