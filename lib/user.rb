# frozen_string_literal: true

require "sequel"

AWAY_MINS = Rational(ENV.fetch("USER_AWAY_THRESHOLD", 5), 24 * 60)

class User < Sequel::Model
  def self.new_from_params(name, zulip_id, email, mac)
    existing = User.first(mac: mac)
    if existing
      existing.update(name: name, zulip_id: zulip_id, email: email)
      existing
    else
      User.create({ name: name, zulip_id: zulip_id, email: email, mac: mac })
    end
  end

  def self.seen_recently
    return User.all if ENV["RACK_ENV"] == "development"

    # find users seen within the last 10 minutes
    User.where { |u| u.last_seen > (DateTime.now - AWAY_MINS) }.all
  end

  def self.seen_recently_printable
    seen_recently.map(&:name)
  end

  def seen!
    set(last_seen: DateTime.now)
    save_changes
  end
end

class NoUser
  def name
    "No registered users"
  end
end
