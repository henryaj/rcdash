require "spec_helper"
require "json"

require "zulip"

describe "Zulip handler" do
  let(:payload) { File.read("spec/fixtures/webhook_payload.json") }
  let(:token) { JSON.parse(payload).fetch("token") }

  before do
    stub_env("ZULIP_SECRET_TOKEN", token)
  end

  it "prompts the user to save their MAC address" do
    response = ZulipHandler.new(payload).respond
    expect(response).to eq({
      :response_string => "Hi. Please send me your MAC address and I'll show you on the RC Dashboard when you're in the space. Or say 'forget' and I'll remove any trace of you from my database."
    })
  end

  context "when the user sends a valid MAC address" do
    let(:payload) { File.read("spec/fixtures/webhook_payload_valid.json") }
    let(:parsed) { JSON.parse(payload) }

    let(:sender_name) { parsed["message"]["sender_full_name"] }
    let(:sender_zulip_id) { parsed["message"]["sender_id"] }
    let(:sender_email) { parsed["message"]["sender_email"] }
    let(:hashed_mac) { "foo" }

    before do
      allow(User).to receive(:new_from_params).and_return(nil)
      allow(Mac).to receive(:hash).and_return(hashed_mac)
    end
    
    it "creates a new user with the MAC address hashed and salted" do
      ZulipHandler.new(payload).respond
      expect(User).to have_received(:new_from_params).with(sender_name, sender_zulip_id, sender_email, hashed_mac)
    end

    it "returns a message" do
      response = ZulipHandler.new(payload).respond
      expect(response).to eq({
        :response_string => "Your MAC address has been stored."
      })
    end
  end

  describe "forgetting a user" do
    let(:fake_user) { double(User) }

    before do
      allow(User).to receive(:where).and_return([])
      allow(User).to receive(:where).with({zulip_id: "5"}).and_return(fake_user)
      allow(fake_user).to receive(:any?).and_return(true)
      allow(fake_user).to receive(:destroy)
    end

    context "when the user exists" do
      let(:payload) { File.read("spec/fixtures/webhook_payload_forget_user_ok.json") }

      it "deletes the user" do
        response = ZulipHandler.new(payload).respond
        expect(response).to eq({
          :response_string => "Okay - I've removed all your devices from the database. You'll stop showing on the dashboard in a few minutes."
        })
        expect(fake_user).to have_received(:destroy)
      end
    end

    context "when the user doesn't exist" do
      let(:payload) { File.read("spec/fixtures/webhook_payload_forget_user_bad.json") }

      it "returns an error message" do
        response = ZulipHandler.new(payload).respond
        expect(response).to eq({
          :response_string => "Nothing to delete. Looks like you never signed up."
        })
      end
    end
  end
end
