require 'sequel'

AWAY_MINS = Rational(ENV.fetch("USER_AWAY_THRESHOLD", 5),24*60)

class User < Sequel::Model
  def self.new_from_params(name, zulip_id, email, mac)
    # TODO: handle dupes
    User.create({name: name, zulip_id: zulip_id, email: email, mac: mac})
  end

  def self.seen_recently
    return User.all if ENV["RACK_ENV"] == "development"

    # find users seen within the last 10 minutes
    User.where { |u| u.last_seen > ( DateTime.now - AWAY_MINS) }.all
  end

  def self.seen_recently_printable
    seen_recently.map { |u| u.name }
  end

  def seen!
    set(last_seen: DateTime.now)
    save
  end
end

class NoUser
  def name
    "No registered users"
  end
end