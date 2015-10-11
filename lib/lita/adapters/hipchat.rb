require "lita"
require "lita/adapters/hipchat/connector"

module Lita
  module Adapters
    class HipChat < Adapter
      namespace "hipchat"

      # Required attributes
      config :jid, type: String, required: true
      config :password, type: String, required: true

      # Optional attributes
      config :server, type: String, default: "chat.hipchat.com"
      config :debug, type: [TrueClass, FalseClass], default: false
      config :rooms, type: [Symbol, Array]
      config :muc_domain, type: String, default: "conf.hipchat.com"
      config :ignore_unknown_users, type: [TrueClass, FalseClass], default: false

      attr_reader :connector

      def initialize(robot)
        super
        @connector = Connector.new(robot, config.jid, config.password, config.server, debug: config.debug)
      end

      def join(room_id)
        connector.join(muc_domain, room_id)
        robot.trigger(:joined, room: room_id)
      end

      def mention_format(name)
        "@#{name}"
      end

      def part(room_id)
        robot.trigger(:parted, room: room_id)
        connector.part(muc_domain, room_id)
      end

      def run
        connector.connect
        robot.trigger(:connected)
        join_persisted_rooms
        create_room_objects
        sleep
      rescue Interrupt
        shut_down
      end

      def send_messages(target, strings)
        if target.private_message?
          connector.message_jid(target.user.id, strings)
        else
          connector.message_muc(target.room, strings)
        end
      end

      def set_topic(target, topic)
        connector.set_topic(target.room, topic)
      end

      def shut_down
        rooms.each { |r| part(r) }
        connector.shut_down
        robot.trigger(:disconnected)
      end

      private

      def create_room_objects
        connector.list_rooms(muc_domain).each do |room|
          room.sub!("@#{muc_domain}", '')
          Room.create_or_update(room)
        end
      end

      def join_all_rooms?
        config.rooms == :all
      end

      def join_persisted_rooms
        rooms.each { |room| join(room) }
      end

      def muc_domain
        config.muc_domain.dup
      end

      def rooms_configured?
        config.rooms.respond_to?(:empty?) && !config.rooms.empty?
      end

      def rooms
        if join_all_rooms? || rooms_configured?
          log.warn(t("config.rooms.deprecated"))

          if config.rooms == :all
            connector.list_rooms(muc_domain)
          else
            Array(config.rooms)
          end
        else
          robot.persisted_rooms
        end
      end
    end

    Lita.register_adapter(:hipchat, HipChat)
  end
end
