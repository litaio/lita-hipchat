require "spec_helper"
describe Lita::User, lita: true do
  describe "#mention_name" do
    it "returns the user's mention name from metadata" do
      subject = described_class.new(1, name: "Carl", mention_name: "carlthepug")
      expect(subject.mention_name).to eq("@carlthepug")
    end

    it "returns the user's name if there is no mention name in the metadata" do
      subject = described_class.new(1, name: "Carl")
      expect(subject.mention_name).to eq("Carl")
    end
  end
end
