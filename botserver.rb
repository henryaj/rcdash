require 'sinatra'
require 'sinatra/json'
require 'json'
require 'erb'

class BotServer < Sinatra::Base
  ZULIP_TOKEN = ENV.fetch("ZULIP_SECRET_TOKEN") # used to ensure we're getting requests from Zulip
  MAC_ADDRESS_REGEX = /^((([a-fA-F0-9][a-fA-F0-9]+[:]){5})([a-fA-F0-9][a-fA-F0-9])$)|(^([a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9]+[.]){2}([a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9]))$/
  
  post "/" do
    body = JSON.parse(request.body.read)
    msg = body.fetch("message")

    validate_token(body.fetch("token"))

    content = msg.fetch("content")
    handle_user_creation(
      msg.fetch("sender_full_name"),
      msg.fetch("sender_id"),
      msg.fetch("sender_email"),
      content
    )
  end

  get "/" do
    @names = User.seen_recently_printable.map
    erb :dash
  end

  def validate_token(token)
    raise if token != BotServer::ZULIP_TOKEN
  end
  
  def handle_user_creation(name, zulip_id, email, content)
    ok = parse_mac_address(content)
    if !ok
      return json :response_string => "Hi. Please send me your MAC address and I'll show you on the RC Dashboard when you're in the space."
    end

    mac = content.gsub("-", ":") # ensure MAC address is stored in format 00:00:00:00:00:00
    User.new_from_params(name, zulip_id, email, mac)
  
    json :response_string => "Your MAC address has been stored."
  end
  
  def parse_mac_address(str)
    result = BotServer::MAC_ADDRESS_REGEX.match(str)
    result ? true : false
  end
end

