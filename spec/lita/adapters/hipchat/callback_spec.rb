require "spec_helper"

describe Lita::Adapters::HipChat::Callback do
  subject { described_class.new(robot, roster) }

  let(:robot) { double("Lita::Robot") }
  let(:roster) { double("Jabber::Roster::Helper") }

  it "has a robot" do
    expect(subject.robot).to eq(robot)
  end

  it "has a roster" do
    expect(subject.roster).to eq(roster)
  end

  describe "#private_message" do
    let(:client) { double("Jabber::Client") }
    let(:message) { double("Lita::Message") }
    let(:jabber_message) do
      double("Jabber::Message", type: :chat, from: "jid", body: "foo")
    end
    let(:source) { double("Lita::Source") }
    let(:user) { double("Lita::User") }

    before do
      allow(client).to receive(:add_message_callback).and_yield(jabber_message)
    end

    it "sends the message to the robot with the proper source and body" do
      allow(subject).to receive(:user_by_jid).with("jid").and_return(user)
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
  end
end
