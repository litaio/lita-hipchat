require "spec_helper"

describe Lita::Adapters::HipChat::Callback, lita: true do
  subject { described_class.new(robot, roster) }

  let(:robot) { double("Lita::Robot") }
  let(:roster) do
    double("Jabber::Roster::Helper", items: { "user_id" => roster_item })
  end
  let(:user) { double("Lita::User", id: "user_id") }
  let(:source) { double("Lita::Source") }
  let(:message) { double("Lita::Message") }
  let(:roster_item) do
    double("Jabber::Roster::RosterItem", attributes: {
      "jid" => "user_id",
      "name" => "Carl",
      "mention_name" => "@Carl"
    }, iname: "Carl")
  end

  before do
    allow(roster).to receive(:[]).with("user_id").and_return(roster_item)
    allow(Lita::User).to receive(:create).with(
      "user_id",
      name: "Carl",
      mention_name: "@Carl"
    ).and_return(user)
  end

  it "has a robot" do
    expect(subject.robot).to eq(robot)
  end

  it "has a roster" do
    expect(subject.roster).to eq(roster)
  end

  describe "#private_message" do
    let(:client) { double("Jabber::Client") }
    let(:jabber_message) do
      double("Jabber::Message", type: :chat, from: "user_id", body: "foo")
    end

    before do
      allow(client).to receive(:add_message_callback).and_yield(jabber_message)
    end

    it "sends the message to the robot with the proper source and body" do
      allow(Lita::Source).to receive(:new).with(user).and_return(source)
      allow(Lita::Message).to receive(:new).with(
        robot,
        "foo",
        source
      ).and_return(message)
      expect(message).to receive(:command!)
      expect(robot).to receive(:receive).with(message)
      subject.private_message(client)
    end

    it "skips the message if it's an error type" do
      allow(jabber_message).to receive(:type).and_return(:error)
      expect(robot).not_to receive(:receive)
      subject.private_message(client)
    end

    it "skips the message if the body is nil" do
      allow(jabber_message).to receive(:body).and_return(nil)
      expect(robot).not_to receive(:receive)
      subject.private_message(client)
    end
  end

  describe "#muc_message" do
    let(:jid) { double("Jabber::JID", bare: "room_id") }
    let(:muc) { double("Jabber::MUC::SimpleMUCClient", jid: jid) }

    before do
      allow(muc).to receive(:on_message).and_yield(nil, "Carl", "foo")
    end

    it "sends the message to the robot with the proper source and body" do
      allow(Lita::Source).to receive(:new).with(
        user,
        "room_id"
      ).and_return(source)
      allow(Lita::Message).to receive(:new).with(
        robot,
        "foo",
        source
      ).and_return(message)
      expect(robot).to receive(:receive).with(message)
      subject.muc_message(muc)
    end
  end

  describe "#roster_update" do
    before do
      allow(roster).to receive(:add_update_callback).and_yield(nil, roster_item)
    end

    it "finds/creates a user object for the roster item" do
      expect(Lita::User).to receive(:create).with(
        "user_id",
        name: "Carl",
        mention_name: "@Carl"
      )
      subject.roster_update
    end
  end
end
