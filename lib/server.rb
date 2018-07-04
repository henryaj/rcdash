require 'sinatra'
require 'sinatra/json'
require 'json'
require 'haml'

require 'auth'
require 'mac'

class Server < Sinatra::Base
  ZULIP_TOKEN = ENV.fetch("ZULIP_SECRET_TOKEN") # used to ensure we're getting requests from Zulip

  enable :sessions
  set :session_secret, ENV.fetch('SESSION_SECRET')

  @@sniffer_last_update = Time.now

  def initialize(auth_handler = Auth.new)
    @auth = auth_handler
    super app
  end
  
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

    @@sniffer_last_update = Time.now

    macs.each do |mac|
      u = User.where(mac: mac)
      if u.any?
        u.first.seen!
      end
    end
  end

  get "/oauth/redirect" do
    redirect @auth.authorize
  end

  get "/oauth/callback" do
    token = @auth.callback(params[:code])
    session[:access_token] = token
    redirect "/"
  end

  get "/" do
    redirect "/oauth/redirect" unless @auth.token_valid?(session[:access_token])

    haml :dash
  end

  get "/users" do
    return status 401 unless session[:access_token] && @auth.token_valid?(session[:access_token])

    @users = User.seen_recently.sort_by { |u| u.name }.map do |u|
      image_url, profile_url = @auth.get_user_details(u.email, session[:access_token])
      {name: u.name, image_url: image_url, profile_url: profile_url}
    end

    json :users => @users, :registered_users => User.all.count, :status_ok => sniffer_okay?
  end

  def validate_token(token)
    raise if token != Server::ZULIP_TOKEN
  end
  
  def handle_message(name, zulip_id, email, content)
    if content == "forget"
      return forget_user(zulip_id)
    end

    if !Mac.valid?(content)
      return json :response_string => "Hi. Please send me your MAC address and I'll show you on the RC Dashboard when you're in the space. Or say 'forget' and I'll remove any trace of you from my database."
    end

    mac = Mac.normalize(content)
    hashed = Mac.hash(mac)
    User.new_from_params(name, zulip_id, email, hashed)
  
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

  def sniffer_okay?
    (Time.now - @@sniffer_last_update) < 120
  end
end

