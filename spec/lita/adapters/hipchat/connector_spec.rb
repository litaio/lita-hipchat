require "spec_helper"

describe Lita::Adapters::HipChat::Connector, lita: true do
  subject { described_class.new(robot, "user", "secret") }

  let(:client) do
    client = instance_double("Jabber::Client")
    allow(robot).to  receive(:trigger)
    allow(client).to receive(:auth)
    allow(client).to receive(:connect)
    allow(client).to receive(:send)
    client
  end

  let(:robot) { instance_double("Lita::Robot", name: "Lita" ) }

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
    let(:presence) { instance_double("Jabber::Presence") }
    let(:callback) { instance_double("Lita::Adapters::HipChat::Callback") }
    let(:roster) { instance_double("Jabber::Roster::Helper") }
    let(:roster_item) do
      instance_double("Jabber::Roster::RosterItem", attributes: { "mention_name" => "LitaBot"})
    end

    before do
      allow(Jabber::Presence).to receive(:new).and_return(presence)
      allow(Jabber::Roster::Helper).to receive(:new).with(client, false).and_return(roster)
      allow(Lita::Adapters::HipChat::Callback).to receive(:new).and_return(callback)
      allow(callback).to receive(:private_message)
      allow(callback).to receive(:roster_update)
      allow(robot).to receive(:mention_name=)
      allow(roster).to receive(:get_roster)
      allow(roster).to receive(:wait_for_roster)
      allow(roster).to receive(:[]).with(subject.jid).and_return(roster_item)
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

    it "assigns the robot's mention_name with info from the roster" do
      expect(robot).to receive(:mention_name=).with("LitaBot")
      subject.connect
    end
  end

  describe "#join" do
    let(:muc) { instance_double("Jabber::MUC::SimpleMUCClient") }
    let(:callback) { instance_double("Lita::Adapters::HipChat::Callback") }

    before do
      allow(Jabber::MUC::SimpleMUCClient).to receive(:new).with(client).and_return(muc)
      allow(Lita::Adapters::HipChat::Callback).to receive(:new).and_return(callback)
      allow(callback).to receive(:muc_message)
      allow(muc).to receive(:join)
    end

    it "stores a SimpleMUCClient for the room" do
      subject.join("conf.hipchat.com", "foo")
      expect(subject.mucs["foo@conf.hipchat.com"]).to eq(muc)
    end

    it "registers a message callback" do
      expect(callback).to receive(:muc_message).with(muc)
      subject.join("conf.hipchat.com", "foo")
    end

    it "joins the room" do
      expect(muc).to receive(:join)
      subject.join("conf.hipchat.com", "foo")
    end

    it "doesn't attempt to join a room it's already in" do
      expect(callback).to receive(:muc_message).with(muc).once
      expect(muc).to receive(:join).once
      2.times { subject.join("conf.hipchat.com", "foo") }
    end
  end

  describe "#join rooms" do
    let(:rooms) { %w(foo bar) }

    it "joins each room" do
      rooms.each { |room| expect(subject).to receive(:join).with("conf.hipchat.com", room) }
      subject.join_rooms("conf.hipchat.com", rooms)
    end
  end

  describe "#list_rooms" do
    let(:browser) { instance_double("Jabber::MUC::MUCBrowser") }

    before do
      allow(Jabber::MUC::MUCBrowser).to receive(:new).with(client).and_return(browser)
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
    let(:message_1) { instance_double("Jabber::Message") }
    let(:message_2) { instance_double("Jabber::Message") }

    it "sends the messages to the user" do
      allow(Jabber::Message).to receive(:new).with("jid", "foo").and_return(message_1)
      allow(Jabber::Message).to receive(:new).with("jid", "bar").and_return(message_2)
      expect(message_1).to receive(:type=).with(:chat)
      expect(message_2).to receive(:type=).with(:chat)
      expect(client).to receive(:send).with(message_1)
      expect(client).to receive(:send).with(message_2)
      subject.message_jid("jid", ["foo", "bar"])
    end
  end

  describe "#message_muc" do
    it "sends the messages to the room" do
      muc = instance_double("Jabber::MUC::SimpleMUCClient")
      allow(subject).to receive(:mucs).and_return("jid" => muc)
      expect(muc).to receive(:say).with("foo")
      expect(muc).to receive(:say).with("bar")
      subject.message_muc("jid", ["foo", "bar"])
    end
  end

  describe "#part" do
    let(:muc) { instance_double("Jabber::MUC::SimpleMUCClient") }

    it "parts from a room" do
      subject.mucs["#foo@conf.hipchat.com"] = muc
      expect(muc).to receive(:exit)
      subject.part("conf.hipchat.com", "#foo")
    end

    it "doesn't attempt to part from a room it's not in" do
      expect(muc).not_to receive(:exit)
      subject.part("conf.hipchat.com", "#foo")
    end
  end

  describe "#set_topic" do
    it "sets the room's topic to the supplied message" do
      muc = instance_double("Jabber::MUC::SimpleMUCClient")
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
