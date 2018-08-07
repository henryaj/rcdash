require 'oauth2'
require 'rest-client'
require 'json'

class AuthHandler
  REDIRECT_URI = "#{ENV.fetch("BASE_URL")}/oauth/callback"
  CLIENT_ID = ENV.fetch("RC_OAUTH_CLIENT_ID")
  CLIENT_SECRET = ENV.fetch("RC_OAUTH_CLIENT_SECRET")

  def client
    @client ||= OAuth2::Client.new(CLIENT_ID, CLIENT_SECRET, site: 'https://www.recurse.com')
  end

  def authorize
    client.auth_code.authorize_url(redirect_uri: REDIRECT_URI)
  end

  def callback(code)
    oauth_token = client.auth_code.get_token(code, redirect_uri: REDIRECT_URI)
    oauth_token.token
  end

  def token_valid?(token)
    return false unless token

    begin
      resp = RestClient.get('https://www.recurse.com/api/v1/profiles/me', { Authorization: "Bearer #{token}" })
      return resp.code == 200
    rescue RestClient::Unauthorized
      return false
    end
  end

  def get_user_details(email, token)
    response = RestClient.get(
      "https://www.recurse.com/api/v1/profiles/#{email}", { Authorization: "Bearer #{token}" }
    )

    image = JSON.parse(response.body).fetch("image_path")
    link = "https://recurse.com/directory/" + JSON.parse(response.body).fetch("slug")

    return image, link
  end
end