require 'oauth2'
require 'rest-client'

class Auth
  REDIRECT_URI = "#{ENV.fetch("BASE_URL")}/oauth/callback"
  CLIENT_ID = ENV.fetch("RC_OAUTH_CLIENT_ID")
  CLIENT_SECRET = ENV.fetch("RC_OAUTH_CLIENT_SECRET")

  def self.client
    @client ||= OAuth2::Client.new(CLIENT_ID, CLIENT_SECRET, site: 'https://www.recurse.com')
  end

  def self.authorize
    client.auth_code.authorize_url(redirect_uri: REDIRECT_URI)
  end

  def self.callback(code)
    oauth_token = client.auth_code.get_token(code, redirect_uri: REDIRECT_URI)
    return oauth_token.token
  end

  def self.token_valid?(token)
    begin
      resp = RestClient.get 'https://www.recurse.com/api/v1/profiles/me', {:Authorization => "Bearer #{token}"}
      return resp.code == 200  
    rescue RestClient::Unauthorized
      return false
    end
  end
end