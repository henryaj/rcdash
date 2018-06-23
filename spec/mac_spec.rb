require 'mac'

describe Mac do
  describe ".valid?" do
    it "returns true if the MAC address is valid" do
      valid_mac = "00:00:00:ff:ff:ff"
      expect(Mac.valid?(valid_mac)).to be true
    end

    it "returns false if the MAC address is invalid" do
      invalid_macs = %w(
        00:00:00:00:00
        00.00.00.00.00.00
        00:00:00:00:00:0q
        00:00:00:00:00:00:00
      ).each do |mac|
        expect(Mac.valid?(mac)).to be false
      end
    end
  end

  describe ".normalize" do
    it "converts the MAC address to a standard format" do
      expect(
        Mac.normalize("00-00-00-ff-ff-ff")
      ).to eq(
        "00:00:00:ff:ff:ff"
      )
    end
  end
end