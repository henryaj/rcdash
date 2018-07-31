require 'sinatra'
require 'sinatra/json'
require 'json'
require 'haml'

require 'app'
require 'auth'
require 'zulip'
require 'mac'

class Server < Sinatra::Base
  enable :sessions
  set :session_secret, ENV.fetch('SESSION_SECRET')

  @@sniffer_last_update = Time.now

  def initialize(auth_handler = AuthHandler.new)
    @auth = auth_handler
    super app
  end
  
  post "/" do
    json_body = request.body.read
    response = ZulipHandler.new(json_body).respond
    json response
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

    json :users => generate_user_list,
         :registered_users => User.all.count,
         :status_ok => sniffer_okay?
  end

  def generate_user_list
    sorted_users = User.seen_recently.sort_by { |u| u.name }.map
    
    user_data = sorted_users.map do |u|
      image_url, profile_url = @auth.get_user_details(u.email, session[:access_token])
      {name: u.name, image_url: image_url, profile_url: profile_url}
    end

    return user_data
  end

  def sniffer_okay?
    (Time.now - @@sniffer_last_update) < 120
  end
end
