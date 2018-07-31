require 'user'
require 'mac'

# For interacting with Zulip's webhook API.
class ZulipHandler
  def initialize(message_json)
    @message_json = message_json
  end

  def respond()
    message = parsed_json.fetch("message")
    token = parsed_json.fetch("token")

    @content = message.fetch("content")
    @sender_name = message.fetch("sender_full_name")
    @sender_zulip_id = message.fetch("sender_id")
    @sender_email = message.fetch("sender_email")

    validate_token(token)

    case content
    when "forget"
      forget_user_and_respond
    else
      store_user_and_respond
    end
  end

  private

  attr_reader :message_json, :sender_zulip_id, :sender_name, :sender_email, :content

  def zulip_secret_token
    @zulip_token ||= ENV.fetch("ZULIP_SECRET_TOKEN")
  end

  def parsed_json
    @parsed_json ||= JSON.parse(message_json)
  end

  def validate_token(token)
    raise if token != zulip_secret_token
  end

  def store_user_and_respond
    unless Mac.valid?(content)
      return zulip_message "Hi. Please send me your MAC address and I'll show you on the RC Dashboard when you're in the space. Or say 'forget' and I'll remove any trace of you from my database."
    end

    mac = Mac.normalize(content)
    hashed = Mac.hash(mac)
    User.new_from_params(sender_name, sender_zulip_id, sender_email, hashed)

    zulip_message "Your MAC address has been stored."
  end

  def forget_user_and_respond
    u = User.where(zulip_id: sender_zulip_id.to_s)
    if u.any?
      u.destroy
      zulip_message "Okay - I've removed all your devices from the database. You'll stop showing on the dashboard in a few minutes."
    else
      zulip_message "Nothing to delete. Looks like you never signed up."
    end
  end

  def zulip_message(msg)
    {:response_string => msg}
  end
end