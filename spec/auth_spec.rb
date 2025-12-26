# frozen_string_literal: true

require "spec_helper"
require "auth"

describe AuthHandler do
  let(:auth_handler) { described_class.new }
  let(:valid_token) { "valid_access_token_123" }
  let(:invalid_token) { "invalid_token" }

  before do
    stub_env("BASE_URL", "http://localhost:9292")
    stub_env("RC_OAUTH_CLIENT_ID", "test_client_id")
    stub_env("RC_OAUTH_CLIENT_SECRET", "test_client_secret")
  end

  describe "#client" do
    it "returns an OAuth2 client configured for Recurse Center" do
      client = auth_handler.client

      expect(client).to be_a(OAuth2::Client)
      expect(client.site).to eq("https://www.recurse.com")
    end

    it "memoizes the client instance" do
      expect(auth_handler.client).to be(auth_handler.client)
    end
  end

  describe "#authorize" do
    it "returns an authorization URL" do
      url = auth_handler.authorize

      expect(url).to include("https://www.recurse.com")
      expect(url).to include("client_id=test_client_id")
    end
  end

  describe "#token_valid?" do
    context "when token is nil" do
      it "returns false" do
        expect(auth_handler.token_valid?(nil)).to be false
      end
    end

    context "when token is valid" do
      before do
        stub_request(:get, "https://www.recurse.com/api/v1/profiles/me")
          .with(headers: { "Authorization" => "Bearer #{valid_token}" })
          .to_return(status: 200, body: '{"id": 1}')
      end

      it "returns true" do
        expect(auth_handler.token_valid?(valid_token)).to be true
      end
    end

    context "when token is invalid" do
      before do
        stub_request(:get, "https://www.recurse.com/api/v1/profiles/me")
          .with(headers: { "Authorization" => "Bearer #{invalid_token}" })
          .to_return(status: 401)
      end

      it "returns false" do
        expect(auth_handler.token_valid?(invalid_token)).to be false
      end
    end
  end

  describe "#get_user_details" do
    let(:email) { "user@example.com" }
    let(:response_body) do
      {
        "image_path" => "https://example.com/image.jpg",
        "slug" => "user-name"
      }.to_json
    end

    before do
      stub_request(:get, "https://www.recurse.com/api/v1/profiles/#{email}")
        .with(headers: { "Authorization" => "Bearer #{valid_token}" })
        .to_return(status: 200, body: response_body)
    end

    it "returns image URL and profile link" do
      image, link = auth_handler.get_user_details(email, valid_token)

      expect(image).to eq("https://example.com/image.jpg")
      expect(link).to eq("https://recurse.com/directory/user-name")
    end
  end
end
