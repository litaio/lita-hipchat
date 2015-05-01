require "lita"
require "lita/adapters/hipchat/connector"
require "lita/adapters/hipchat/user"

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
        rooms.each { |r| join(r) }
        sleep
      rescue Errno::ECONNRESET => e
        Lita.logger.error(e)
        shut_down
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

      def rooms
        if config.rooms == :all
          connector.list_rooms(muc_domain)
        else
          Array(config.rooms)
        end
      end

      def muc_domain
        config.muc_domain.dup
      end

    end

    Lita.register_adapter(:hipchat, HipChat)
  end
end
