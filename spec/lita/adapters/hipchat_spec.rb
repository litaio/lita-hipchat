require "spec_helper"

describe Lita::Adapters::HipChat, lita: true do
  before do
    registry.register_adapter(:hipchat, described_class)

    registry.configure do |config|
      config.adapters.hipchat.jid = "jid"
      config.adapters.hipchat.password = "secret"
    end

    allow(described_class::Connector).to receive(:new).and_return(connector)
  end

  subject { described_class.new(robot) }

  let(:robot) { Lita::Robot.new(registry) }
  let(:connector) { instance_double("Lita::Adapters::HipChat::Connector") }
  let(:domain) { "conf.hipchat.com" }

  it "registers with Lita" do
    expect(Lita.adapters[:hipchat]).to eql(described_class)
  end

  describe "#join" do
    let(:room) { "#foo" }
    before do
      allow(robot).to receive(:trigger).with(:joined, room: room)
    end
    it "joins a room" do
      expect(subject.connector).to receive(:join).with(domain, room)
      subject.join(room)
    end
  end

  describe "#join_persisted_rooms" do
    it "attempts to join persisted_rooms" do
      expect(robot).to receive(:respond_to?).and_return(true)
      expect(robot).to receive(:persisted_rooms).twice.and_return(["room_3_id", "room_4_id"])
      expect(subject).to receive(:join).twice
      subject.join_persisted_rooms(robot)
    end

    it "handles empty persisted_rooms well" do
      expect(robot).to receive(:respond_to?).and_return(true)
      expect(robot).to receive(:persisted_rooms).twice.and_return([])
      expect(subject).to_not receive(:join)
      expect { subject.join_persisted_rooms(robot) }.to_not raise_exception
    end

    it "handles nil persisted_rooms well" do
      expect(robot).to receive(:respond_to?).and_return(true)
      expect(robot).to receive(:persisted_rooms).once.and_return(nil)
      expect(subject).to_not receive(:join)
      expect { subject.join_persisted_rooms(robot) }.to_not raise_exception
    end

    it "handles not responding to persisted_rooms well" do
      expect(robot).to receive(:respond_to?).and_return(false)
      expect(robot).to_not receive(:persisted_rooms)
      expect(subject).to_not receive(:join)
      expect { subject.join_persisted_rooms(robot) }.to_not raise_exception
    end
  end

  describe "#mention_format" do
    it "returns the name prefixed with an @" do
      expect(subject.mention_format("carl")).to eq("@carl")
    end
  end

  describe "#part" do
    let(:room) { "#foo" }
    before do
      allow(robot).to receive(:trigger).with(:parted, room: room)
    end
    it "parts from a room" do
      expect(subject.connector).to receive(:part).with(domain, room)
      subject.part(room)
    end
  end

  describe "#run" do
    let(:rooms) { ["room_1_id", "room_2_id"] }

    before do
      allow(subject.connector).to receive(:connect)
      allow(robot).to receive(:trigger)
      allow(subject.connector).to receive(:join)
      allow(subject).to receive(:sleep)
    end

    it "connects to HipChat" do
      expect(subject.connector).to receive(:connect)
      expect(robot).to receive(:trigger).with(:connected)
      subject.run
    end

    it "reconnects to persisted_rooms" do
      expect(robot).to receive(:persisted_rooms).twice.and_return(["room_3_id", "room_4_id"])
      expect(subject).to receive(:join).with("room_3_id")
      expect(subject).to receive(:join).with("room_4_id")
      subject.run
    end

    context "with a custom domain" do
      let(:domain) { "foo.bar.com" }
      it "joins rooms with a custom muc_domain" do
        registry.config.adapters.hipchat.muc_domain = domain
        allow(subject).to receive(:rooms).and_return(rooms)
        expect(subject.connector).to receive(:join).with(domain, anything)
        subject.run
      end
    end

    it "joins all rooms when config.rooms is :all" do
      registry.config.adapters.hipchat.rooms = :all
      allow(subject.connector).to receive(:list_rooms).with(domain).and_return(rooms)
      rooms.each do |room|
        expect(subject).to receive(:join).with(room)
      end
      subject.run
    end

    it "joins rooms specified by config.rooms" do
      custom_rooms = rooms
      registry.config.adapters.hipchat.rooms = custom_rooms
      rooms.each do |room|
        expect(subject).to receive(:join).with(room)
      end
      subject.run
    end

    it "sleeps the main thread" do
      expect(subject).to receive(:sleep)
      subject.run
    end

    it "disconnects gracefully on interrupt" do
      expect(subject).to receive(:shut_down)
      allow(subject).to receive(:sleep).and_raise(Interrupt)
      subject.run
    end
  end

  describe "#send_messages" do
    it "sends messages to rooms" do
      source = instance_double("Lita::Source", room: "room_id", private_message?: false)
      expect(subject.connector).to receive(:message_muc).with("room_id", ["Hello!"])
      subject.send_messages(source, ["Hello!"])
    end

    it "sends private messages to users" do
      user = instance_double("Lita::User", id: "user_id")
      source = instance_double("Lita::Source", user: user, private_message?: true)
      expect(subject.connector).to receive(:message_jid).with("user_id", ["Hello!"])
      subject.send_messages(source, ["Hello!"])
    end
  end

  describe "#set_topic" do
    it "sets a new topic for a room" do
      source = instance_double("Lita::Source", room: "room_id")
      expect(subject.connector).to receive(:set_topic).with("room_id", "Topic")
      subject.set_topic(source, "Topic")
    end
  end

  describe "#shut_down" do
    it "shuts down the connector" do
      expect(subject.connector).to receive(:shut_down)
      allow(robot).to receive(:trigger)
      allow(subject.connector).to receive(:part)
      expect(robot).to receive(:trigger).with(:disconnected)
      subject.shut_down
    end
  end
end
