require 'sinatra'
require 'sinatra/json'
require 'json'
require 'haml'

require 'auth'

class Server < Sinatra::Base
  ZULIP_TOKEN = ENV.fetch("ZULIP_SECRET_TOKEN") # used to ensure we're getting requests from Zulip
  MAC_ADDRESS_REGEX = /^((([a-fA-F0-9][a-fA-F0-9]+[:]){5})([a-fA-F0-9][a-fA-F0-9])$)|(^([a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9]+[.]){2}([a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9]))$/

  enable :sessions
  set :session_secret, ENV.fetch('SESSION_SECRET')
  
  post "/" do
    body = JSON.parse(request.body.read)
    msg = body.fetch("message")

    validate_token(body.fetch("token"))

    content = msg.fetch("content")
    handle_message(
      msg.fetch("sender_full_name"),
      msg.fetch("sender_id"),
      msg.fetch("sender_email"),
      content
    )
  end

  post "/macs_seen" do
    body = JSON.parse(request.body.read)
    macs = body.fetch("seen")

    macs.each do |mac|
      u = User.where(mac: mac)
      if u.any?
        u.first.seen!
      end
    end
  end

  get "/oauth/redirect" do
    redirect Auth.authorize
  end

  get "/oauth/callback" do
    token = Auth.callback(params[:code])
    session[:access_token] = token
    redirect "/"
  end

  get "/" do
    redirect "/oauth/redirect" unless session[:access_token]
    redirect "/oauth/redirect" unless Auth.token_valid?(session[:access_token])

    haml :dash
  end

  get "/users" do
    return status 401 unless session[:access_token] && Auth.token_valid?(session[:access_token])

    @users = User.seen_recently.sort_by { |u| u.name }.map do |u|
      image_url, profile_url = Auth.get_user_details(u.email, session[:access_token])
      {name: u.name, image_url: image_url, profile_url: profile_url}
    end

    json :users => @users, :registered_users => User.all.count
  end

  def validate_token(token)
    raise if token != Server::ZULIP_TOKEN
  end
  
  def handle_message(name, zulip_id, email, content)
    if content == "forget"
      return forget_user(zulip_id)
    end

    ok = parse_mac_address(content)
    if !ok
      return json :response_string => "Hi. Please send me your MAC address and I'll show you on the RC Dashboard when you're in the space. Or say 'forget' and I'll remove any trace of you from my database."
    end

    mac = content.gsub("-", ":") # ensure MAC address is stored in format 00:00:00:00:00:00
    User.new_from_params(name, zulip_id, email, mac)
  
    json :response_string => "Your MAC address has been stored."
  end

  def forget_user(zulip_id)
    u = User.where(zulip_id: zulip_id.to_s)
    if u.any?
      u.destroy 
      return json :response_string => "Okay - I've removed all your devices from the database. You'll stop showing on the dashboard in a few minutes."
    else
      return json :response_string => "Nothing to delete. Looks like you never signed up."
    end
  end
  
  def parse_mac_address(str)
    result = Server::MAC_ADDRESS_REGEX.match(str)
    result ? true : false
  end
end

