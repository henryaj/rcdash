require 'rack/test'
require 'server'
require 'auth'

describe "server" do
  include Rack::Test::Methods
  let(:auth_handler) { instance_double(Auth) }

  def app
    Server.new(auth_handler)
  end

  it "displays the dashboard" do
    fake_access_token = "foobarbaz"

    allow(auth_handler).to receive(:token_valid?).with(fake_access_token)
      .and_return(true)

    env "rack.session", {:access_token => fake_access_token}
    get "/"
    
    expect(last_response).to be_ok
  end
end