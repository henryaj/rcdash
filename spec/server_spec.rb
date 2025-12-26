# frozen_string_literal: true

require "spec_helper"
require "rack/test"
require "json"
require "app"

describe "server" do
  include Rack::Test::Methods

  let(:auth_handler) { instance_double(AuthHandler) }
  let(:valid_token) { "valid_token_123" }

  before do
    stub_env("SESSION_SECRET", "test_secret_at_least_64_characters_long_for_security_in_tests_1234567890")
    stub_env("ZULIP_SECRET_TOKEN", "test_zulip_token")
    stub_env("SALT", "test_salt")
    # Clean up users before each test
    User.dataset.delete
  end

  def app
    Server.new(auth_handler)
  end

  describe "GET /" do
    context "when authenticated" do
      before do
        allow(auth_handler).to receive(:token_valid?).and_return(true)
      end

      it "displays the dashboard" do
        get "/"

        expect(last_response).to be_ok
      end
    end

    context "when not authenticated" do
      before do
        allow(auth_handler).to receive(:token_valid?).and_return(false)
        allow(auth_handler).to receive(:authorize).and_return("https://recurse.com/oauth/authorize")
      end

      it "redirects to OAuth" do
        get "/"

        expect(last_response).to be_redirect
      end
    end
  end

  describe "GET /oauth/redirect" do
    let(:oauth_url) { "https://www.recurse.com/oauth/authorize?client_id=test" }

    before do
      allow(auth_handler).to receive(:authorize).and_return(oauth_url)
    end

    it "redirects to the OAuth provider" do
      get "/oauth/redirect"

      expect(last_response).to be_redirect
      expect(last_response.location).to eq(oauth_url)
    end
  end

  describe "GET /oauth/callback" do
    let(:auth_code) { "auth_code_123" }
    let(:access_token) { "access_token_456" }

    before do
      allow(auth_handler).to receive(:callback).with(auth_code).and_return(access_token)
    end

    it "exchanges code for token and redirects to root" do
      get "/oauth/callback", code: auth_code

      expect(last_response).to be_redirect
      expect(last_response.location).to end_with("/")
    end
  end

  describe "GET /users" do
    context "when authenticated" do
      before do
        allow(auth_handler).to receive(:token_valid?).and_return(true)
        allow(auth_handler).to receive(:get_user_details).and_return(["image.jpg", "profile_url"])

        User.create(
          name: "Test User",
          zulip_id: "1",
          email: "test@example.com",
          mac: "mac1",
          last_seen: DateTime.now
        )
      end

      it "returns JSON with user list" do
        get "/users", {}, { "rack.session" => { access_token: valid_token } }

        expect(last_response).to be_ok
        expect(last_response.content_type).to include("application/json")

        body = JSON.parse(last_response.body)
        expect(body).to have_key("users")
        expect(body).to have_key("registered_users")
        expect(body).to have_key("status_ok")
      end
    end

    context "when not authenticated" do
      before do
        allow(auth_handler).to receive(:token_valid?).and_return(false)
      end

      it "returns 401 unauthorized" do
        get "/users"

        expect(last_response.status).to eq(401)
      end
    end
  end

  describe "POST /" do
    let(:zulip_token) { "test_zulip_token" }
    let(:payload) do
      {
        token: zulip_token,
        message: {
          content: "hello",
          sender_full_name: "Test User",
          sender_id: 123,
          sender_email: "test@example.com"
        }
      }.to_json
    end

    it "processes Zulip webhook and returns JSON response" do
      post "/", payload, "CONTENT_TYPE" => "application/json"

      expect(last_response).to be_ok
      expect(last_response.content_type).to include("application/json")
    end
  end

  describe "POST /macs_seen" do
    before do
      User.create(
        name: "Test User",
        zulip_id: "1",
        email: "test@example.com",
        mac: "hashed_mac_1",
        last_seen: DateTime.now - 1
      )
    end

    let(:mac_payload) { { seen: %w[hashed_mac_1 hashed_mac_2] }.to_json }

    it "updates last_seen for matching users" do
      old_last_seen = User.first(mac: "hashed_mac_1").last_seen

      post "/macs_seen", mac_payload, "CONTENT_TYPE" => "application/json"

      user = User.first(mac: "hashed_mac_1")
      expect(user.last_seen).to be > old_last_seen
    end
  end
end
