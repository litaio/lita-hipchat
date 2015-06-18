require "spec_helper"

describe Lita::Adapters::HipChat, lita: true do
  before do
    registry.register_adapter(:hipchat, described_class)

    registry.configure do |config|
      config.adapters.hipchat.jid = "jid"
      config.adapters.hipchat.password = "secret"
      config.adapters.hipchat.muc_domain = domain
      config.adapters.hipchat.rooms = rooms
    end

    allow(described_class::Connector).to receive(:new).and_return(connector)
  end

  subject { described_class.new(robot) }

  let(:robot) { Lita::Robot.new(registry) }
  let(:connector) { instance_double("Lita::Adapters::HipChat::Connector") }
  let(:domain) { "conf.hipchat.com" }
  let(:rooms) { %w(room_1, room_2) }

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

    context "with a custom domain" do
      let(:domain) { "foo.bar.com" }

      it "joins rooms with a custom muc_domain" do
        expect(subject.connector).to receive(:join).with(domain, anything)

        subject.run
      end
    end

    context "when config.rooms is :all" do
      before do
        allow(subject.connector).to receive(:list_rooms).and_return(%w(room_1 room_2))
        allow(subject.connector).to receive(:join)
      end

      let(:rooms) { :all }

      it "logs a deprecation warning" do
        expect(Lita.logger).to receive(:warn) do |msg|
          expect(msg).to include("config.rooms is deprecated")
        end

        subject.run
      end

      it "joins all rooms" do
        %w(room_1 room_2).each do |room|
          expect(subject.connector).to receive(:join).with(domain, room)
        end

        subject.run
      end
    end

    context "when config.rooms contains individual room IDs" do
      let(:rooms) { ["room_1_only"] }

      it "logs a deprecation warning" do
        expect(Lita.logger).to receive(:warn) do |msg|
          expect(msg).to include("config.rooms is deprecated")
        end

        subject.run
      end

      it "joins the specified rooms" do
        expect(subject.connector).to receive(:join).with(domain, "room_1_only")

        subject.run
      end
    end

    context "when config.rooms is empty" do
      before { allow(robot).to receive(:persisted_rooms).and_return(%w(persisted_room_1)) }

      let(:rooms) { [] }

      it "joins rooms persisted in robot.persisted_rooms" do
        expect(subject.connector).to receive(:join).with(domain, "persisted_room_1")

        subject.run
      end
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
