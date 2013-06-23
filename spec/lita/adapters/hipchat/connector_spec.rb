require "spec_helper"

describe Lita::Adapters::HipChat::Connector do
  it "sets the JID properly when only a node is supplied" do
    subject = described_class.new("user", "secret")
    expect(subject.jid).to eq("user@chat.hipchat.com/bot")
  end

  it "sets the JID properly when a node and domain are supplied" do
    subject = described_class.new("user@example.com", "secret")
    expect(subject.jid).to eq("user@example.com/bot")
  end

  it "sets the JID properly when a resource is supplied" do
    subject = described_class.new("user@example.com/wrong", "secret")
    expect(subject.jid).to eq("user@example.com/bot")
  end

  it "turns on the xmpp4r logger if debug: true is supplied" do
    expect(Jabber).to receive(:debug=).with(true)
    subject = described_class.new("user", "secret", debug: true)
  end

  describe "#connect" do
    subject { described_class.new("user", "secret") }

    let(:client) { double("Jabber::Client").as_null_object }
    let(:presence) { double("Jabber::Presence") }
    let(:roster) { double("Jabber::Roster::Helper").as_null_object }

    before do
      allow(subject).to receive(:client).and_return(client)
      allow(Jabber::Presence).to receive(:new).and_return(presence)
      allow(Jabber::Roster::Helper).to receive(:new).with(client).and_return(
        roster
      )
    end

    it "connects to HipChat" do
      expect(subject.client).to receive(:connect)
      subject.connect
    end

    it "authenticates with the supplied password" do
      expect(subject.client).to receive(:auth).with("secret")
      subject.connect
    end

    it "sends an initial presence of :chat" do
      expect(Jabber::Presence).to receive(:new).with(:chat).and_return(presence)
      expect(subject.client).to receive(:send).with(presence)
      subject.connect
    end

    it "registers a message callback" do
      expect(subject.client).to receive(:add_message_callback)
      subject.connect
    end

    it "loads a roster" do
      expect(roster).to receive(:wait_for_roster)
      subject.connect
    end
  end
end
