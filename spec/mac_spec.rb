# frozen_string_literal: true

require "spec_helper"
require "mac"

describe Mac do
  describe ".valid?" do
    it "returns true if the MAC address is valid" do
      valid_mac = "00:00:00:ff:ff:ff"
      expect(described_class.valid?(valid_mac)).to be true
    end

    it "returns false if the MAC address is invalid" do
      %w[
        00:00:00:00:00
        00.00.00.00.00.00
        00:00:00:00:00:0q
        00:00:00:00:00:00:00
      ].each do |mac|
        expect(described_class.valid?(mac)).to be false
      end
    end
  end

  describe ".normalize" do
    it "converts the MAC address to a standard format" do
      expect(
        described_class.normalize("00-00-00-ff-ff-ff")
      ).to eq(
        "00:00:00:ff:ff:ff"
      )
    end
  end

  describe ".hash" do
    before do
      stub_env("SALT", "test_salt")
    end

    it "returns a SHA256 hash of the MAC address with salt" do
      mac = "00:00:00:ff:ff:ff"
      hashed = described_class.hash(mac)

      expect(hashed).to be_a(String)
      expect(hashed).not_to eq(mac)
      expect(hashed.length).to eq(44) # Base64-encoded SHA256 is 44 chars
    end

    it "produces consistent hashes for the same input" do
      mac = "00:00:00:ff:ff:ff"

      expect(described_class.hash(mac)).to eq(described_class.hash(mac))
    end

    it "produces different hashes for different inputs" do
      mac1 = "00:00:00:ff:ff:ff"
      mac2 = "00:00:00:ff:ff:fe"

      expect(described_class.hash(mac1)).not_to eq(described_class.hash(mac2))
    end
  end
end
