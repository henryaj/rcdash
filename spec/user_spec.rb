# frozen_string_literal: true

require "spec_helper"
require "app"

describe User do
  before do
    stub_env("USER_AWAY_THRESHOLD", "5")
    # Clean up users before each test
    described_class.dataset.delete
  end

  describe ".new_from_params" do
    it "creates a new user with the given parameters" do
      user = described_class.new_from_params("Test User", "123", "test@example.com", "hashed_mac")

      expect(user.name).to eq("Test User")
      expect(user.zulip_id).to eq("123")
      expect(user.email).to eq("test@example.com")
      expect(user.mac).to eq("hashed_mac")
    end
  end

  describe ".seen_recently" do
    let!(:recent_user) do
      described_class.create(
        name: "Recent User",
        zulip_id: "1",
        email: "recent@example.com",
        mac: "mac1",
        last_seen: DateTime.now
      )
    end

    let!(:old_user) do
      described_class.create(
        name: "Old User",
        zulip_id: "2",
        email: "old@example.com",
        mac: "mac2",
        last_seen: DateTime.now - Rational(10, 24 * 60) # 10 minutes ago
      )
    end

    context "when in production environment" do
      before do
        stub_env("RACK_ENV", "production")
      end

      it "returns only users seen within the threshold" do
        result = described_class.seen_recently

        expect(result).to include(recent_user)
        expect(result).not_to include(old_user)
      end
    end

    context "when in development environment" do
      before do
        stub_env("RACK_ENV", "development")
      end

      it "returns all users" do
        result = described_class.seen_recently

        expect(result).to include(recent_user)
        expect(result).to include(old_user)
      end
    end
  end

  describe ".seen_recently_printable" do
    before do
      stub_env("RACK_ENV", "production")
      described_class.create(
        name: "Test User",
        zulip_id: "1",
        email: "test@example.com",
        mac: "mac1",
        last_seen: DateTime.now
      )
    end

    it "returns an array of user names" do
      expect(described_class.seen_recently_printable).to eq(["Test User"])
    end
  end

  describe "#seen!" do
    let(:user) do
      described_class.create(
        name: "Test User",
        zulip_id: "1",
        email: "test@example.com",
        mac: "mac1",
        last_seen: DateTime.now - 1 # 1 day ago
      )
    end

    it "updates the last_seen timestamp to now" do
      Timecop.freeze(Time.now) do
        old_last_seen = user.last_seen
        user.seen!
        user.refresh

        expect(user.last_seen).to be > old_last_seen
      end
    end
  end
end

describe NoUser do
  describe "#name" do
    it "returns a placeholder message" do
      expect(described_class.new.name).to eq("No registered users")
    end
  end
end
