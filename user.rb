require 'sequel'

class User < Sequel::Model
  def self.new_from_params(name, zulip_id, email, mac)
    # TODO: handle dupes
    User.create({name: name, zulip_id: zulip_id, email: email, mac: mac})
  end

  def self.seen_recently
    # find users seen within the last 15 minutes
    User.where { |u| u.last_seen > ( DateTime.now - 15/60/24 ) }.all
  end

  def self.seen_recently_printable
    seen_recently.map { |u| u.name }.join(", ")
  end

  def seen!
    last_seen = DateTime.now
  end
end