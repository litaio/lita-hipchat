require "spec_helper"

describe Lita::Adapters::HipChat do
  before do
    Lita.configure do |config|
      config.adapter.jid = "jid"
      config.adapter.password = "secret"
      config.adapter.rooms = nil
      config.adapter.muc_domain = nil
    end

    allow(described_class::Connector).to receive(:new).and_return(connector)
  end

  subject { described_class.new(robot) }

  let(:robot) { instance_double("Lita::Robot") }
  let(:connector) { instance_double("Lita::Adapters::HipChat::Connector") }

  it "registers with Lita" do
    expect(Lita.adapters[:hipchat]).to eql(described_class)
  end

  it "requires config.jid and config.password" do
    Lita.config.adapter.jid = Lita.config.adapter.password = nil
    expect(Lita.logger).to receive(:fatal).with(/jid, password/)
    expect { subject }.to raise_error(SystemExit)
  end

  describe "#join" do
    it "joins a room" do
      expect(subject.connector).to receive(:join).with("conf.hipchat.com", "#foo")
      subject.join("#foo")
    end
  end

  describe "#part" do
    it "parts from a room" do
      expect(subject.connector).to receive(:part).with("conf.hipchat.com", "#foo")
      subject.part("#foo")
    end
  end

  describe "#run" do
    before do
      allow(subject.connector).to receive(:connect)
      allow(robot).to receive(:trigger)
      allow(subject.connector).to receive(:join_rooms)
      allow(subject).to receive(:sleep)
    end

    it "connects to HipChat" do
      expect(subject.connector).to receive(:connect)
      expect(robot).to receive(:trigger).with(:connected)
      subject.run
    end

    it "joins rooms with a custom muc_domain" do
      Lita.config.adapter.muc_domain = "foo.bar.com"
      expect(subject.connector).to receive(:join_rooms).with("foo.bar.com", anything)
      subject.run
    end

    it "joins all rooms when config.rooms is :all" do
      rooms = ["room_1_id", "room_2_id"]
      Lita.config.adapter.rooms = :all
      allow(subject.connector).to receive(:list_rooms).with("conf.hipchat.com").and_return(rooms)
      expect(subject.connector).to receive(:join_rooms).with("conf.hipchat.com", rooms)
      subject.run
    end

    it "joins rooms specified by config.rooms" do
      custom_rooms = ["my_room_1_id", "my_room_2_id"]
      Lita.config.adapter.rooms = custom_rooms
      expect(subject.connector).to receive(:join_rooms).with("conf.hipchat.com",custom_rooms)
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
      expect(robot).to receive(:trigger).with(:disconnected)
      subject.shut_down
    end
  end
end
