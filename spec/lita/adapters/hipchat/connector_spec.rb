require "spec_helper"

describe Lita::Adapters::HipChat::Connector do
  subject { described_class.new(robot, "user", "secret") }

  let(:client) { double("Jabber::Client").as_null_object }
  let(:robot) { double("Lita::Robot", name: "Lita" ) }

  before { allow(subject).to receive(:client).and_return(client) }

  it "sets the JID properly when only a node is supplied" do
    subject = described_class.new(robot, "user", "secret")
    expect(subject.jid).to eq("user@chat.hipchat.com/bot")
  end

  it "sets the JID properly when a node and domain are supplied" do
    subject = described_class.new(robot, "user@example.com", "secret")
    expect(subject.jid).to eq("user@example.com/bot")
  end

  it "sets the JID properly when a resource is supplied" do
    subject = described_class.new(robot, "user@example.com/wrong", "secret")
    expect(subject.jid).to eq("user@example.com/bot")
  end

  it "turns on the xmpp4r logger if debug: true is supplied" do
    expect(Jabber).to receive(:debug=).with(true)
    subject = described_class.new(robot, "user", "secret", debug: true)
  end

  describe "#connect" do
    let(:presence) { double("Jabber::Presence") }
    let(:roster) { double("Jabber::Roster::Helper").as_null_object }
    let(:callback) { double("Lita::Adapters::HipChat::Callback") }

    before do
      allow(Jabber::Presence).to receive(:new).and_return(presence)
      allow(Jabber::Roster::Helper).to receive(:new).with(client).and_return(
        roster
      )
      allow(Lita::Adapters::HipChat::Callback).to receive(:new).and_return(
        callback
      )
      allow(callback).to receive(:private_message)
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
      expect(Lita::Adapters::HipChat::Callback).to receive(:new).with(
        robot,
        roster
      ).and_return(callback)
      expect(callback).to receive(:private_message).with(client)
      subject.connect
    end

    it "loads a roster" do
      expect(roster).to receive(:wait_for_roster)
      subject.connect
    end
  end

  describe "#join rooms" do
    let(:muc_domain) { "conf.hipchat.com" }
    let(:rooms) { ["muc_1", "muc_2"] }
    let(:muc_1) { double("Jabber::MUC::SimpleMUCClient").as_null_object }
    let(:muc_2) { double("Jabber::MUC::SimpleMUCClient").as_null_object }

    before do
      allow(Jabber::MUC::SimpleMUCClient).to receive(:new).with(
        client
      ).and_return(muc_1, muc_2)
    end

    it "creates a SimpleMUCClient for each room" do
      subject.join_rooms(muc_domain, rooms)
      expect(subject.mucs).to eq(
        "muc_1@conf.hipchat.com" => muc_1,
        "muc_2@conf.hipchat.com" => muc_2,
      )
    end

    it "registers a message callback for each room" do
      expect(muc_1).to receive(:on_message)
      expect(muc_2).to receive(:on_message)
      subject.join_rooms(muc_domain, rooms)
    end

    it "joins each room" do
      expect(muc_1).to receive(:join)
      expect(muc_2).to receive(:join)
      subject.join_rooms(muc_domain, rooms)
    end
  end

  describe "#list_rooms" do
    let(:browser) { double("Jabber::MUC::MUCBrowser") }

    before do
      allow(Jabber::MUC::MUCBrowser).to receive(:new).with(client).and_return(
        browser
      )
    end

    it "returns an array of room JIDs for the MUC domain" do
      allow(browser).to receive(:muc_rooms).with("conf.hipchat.com").and_return(
        "123_456@conf.hipchat.com" => "Room 1",
        "789_012@conf.hipchat.com" => "Room 2"
      )
      expect(subject.list_rooms("conf.hipchat.com")).to eq([
        "123_456@conf.hipchat.com",
        "789_012@conf.hipchat.com"
      ])
    end
  end

  describe "#message_jid" do
    let(:message_1) { double("Jabber::Message") }
    let(:message_2) { double("Jabber::Message") }

    it "sends the messages to the user" do
      allow(Jabber::Message).to receive(:new).with("jid", "foo").and_return(
        message_1
      )
      allow(Jabber::Message).to receive(:new).with("jid", "bar").and_return(
        message_2
      )
      expect(message_1).to receive(:type=).with(:chat)
      expect(message_2).to receive(:type=).with(:chat)
      expect(client).to receive(:send).with(message_1)
      expect(client).to receive(:send).with(message_2)
      subject.message_jid("jid", ["foo", "bar"])
    end
  end

  describe "#message_muc" do
    it "sends the messages to the room" do
      muc = double("Jabber::MUC::SimpleMUCClient")
      allow(subject).to receive(:mucs).and_return("jid" => muc)
      expect(muc).to receive(:say).with("foo")
      expect(muc).to receive(:say).with("bar")
      subject.message_muc("jid", ["foo", "bar"])
    end
  end

  describe "#set_topic" do
    it "sets the room's topic to the supplied message" do
      muc = double("Jabber::MUC::SimpleMUCClient")
      allow(subject).to receive(:mucs).and_return("jid" => muc)
      expect(muc).to receive(:subject=).with("New topic")
      subject.set_topic("jid", "New topic")
    end
  end

  describe "#shut_down" do
    it "closes the client connection" do
      expect(subject.client).to receive(:close)
      subject.shut_down
    end
  end
end
