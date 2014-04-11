require "lita"
require "lita/adapters/hipchat/connector"

module Lita
  module Adapters
    class HipChat < Adapter
      require_configs :jid, :password

      attr_reader :connector

      def initialize(robot)
        super

        @connector = Connector.new(robot, config.jid, config.password, debug: debug)
      end

      def join(room_id)
        connector.join(muc_domain, room_id)
      end

      def mention_format(name)
        "@#{name}"
      end

      def part(room_id)
        connector.part(muc_domain, room_id)
      end

      def run
        connector.connect
        robot.trigger(:connected)
        connector.join_rooms(muc_domain, rooms)
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
        connector.shut_down
        robot.trigger(:disconnected)
      end

      private

      def config
        Lita.config.adapter
      end

      def debug
        config.debug || false
      end

      def muc_domain
        config.muc_domain.nil? ? "conf.hipchat.com" : config.muc_domain.dup
      end

      def rooms
        if config.rooms == :all
          connector.list_rooms(muc_domain)
        else
          Array(config.rooms)
        end
      end
    end

    Lita.register_adapter(:hipchat, HipChat)
  end
end
