# frozen_string_literal: true

require "sinatra"
require "sinatra/json"
require "json"
require "haml"

require "app"
require "auth"
require "zulip"
require "mac"

class Server < Sinatra::Base
  enable :sessions
  set :session_secret, ENV.fetch("SESSION_SECRET")
  set :host_authorization, permitted_hosts: [], allow_if: ->(_) { true } if test?

  # Thread-safe sniffer status tracking
  @sniffer_mutex = Mutex.new
  @sniffer_last_update = Time.now

  class << self
    attr_reader :sniffer_mutex
    attr_accessor :sniffer_last_update
  end

  def initialize(auth_handler = AuthHandler.new)
    @auth = auth_handler
    super(app)
  end

  helpers do
    def authenticated?
      session[:access_token] && @auth.token_valid?(session[:access_token])
    end

    def require_authentication!
      halt 401, "Unauthorized" unless authenticated?
    end

    def valid_sniffer_api_key?
      api_key = request.env["HTTP_X_API_KEY"]
      expected_key = ENV.fetch("SNIFFER_API_KEY", nil)

      # If no API key is configured, allow requests (backwards compatibility)
      return true if expected_key.nil? || expected_key.empty?

      api_key == expected_key
    end
  end

  post "/" do
    json_body = request.body.read
    response = ZulipHandler.new(json_body).respond
    json response
  end

  post "/macs_seen" do
    halt 401, "Unauthorized" unless valid_sniffer_api_key?

    body = JSON.parse(request.body.read)
    macs = body.fetch("seen")

    self.class.sniffer_mutex.synchronize do
      self.class.sniffer_last_update = Time.now
    end

    macs.each do |mac|
      u = User.where(mac: mac)
      u.first.seen! if u.any?
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
    require_authentication!

    json users: generate_user_list,
         registered_users: User.all.count,
         status_ok: sniffer_okay?
  end

  def generate_user_list
    User.seen_recently.sort_by(&:name)
        .map do |u|
          image_url, profile_url = @auth.get_user_details(u.email, session[:access_token])
          { name: u.name, image_url: image_url, profile_url: profile_url }
    end
  end

  def sniffer_okay?
    self.class.sniffer_mutex.synchronize do
      (Time.now - self.class.sniffer_last_update) < 120
    end
  end
end
