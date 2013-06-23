require "lita"
require "lita/adapters/hipchat/connector"

module Lita
  module Adapters
    class HipChat < Adapter
      require_configs :jid, :password

      attr_reader :connector

      def initialize(robot)
        super

        set_default_config_values

        @connector = Connector.new(
          config.jid,
          config.password,
          debug: config.debug
        )
      end

      def run
        connector.connect
        connector.join_rooms(config.muc_domain, rooms)
        sleep
      rescue Interrupt
        shut_down
      end

      def send_messages(target, strings)
        if target.room
          connector.message_muc(target.room, strings)
        else
          connector.message_jid(target.user.id, strings)
        end
      end

      def set_topic(target, topic)
        connector.set_topic(target.room, topic)
      end

      def shut_down
        connector.shut_down
      end

      private

      def config
        Lita.config.adapter
      end

      def rooms
        if config.rooms == :all
          connector.list_rooms(config.muc_domain)
        else
          Array(config.rooms)
        end
      end

      def set_default_config_values
        config.debug = false if config.debug.nil?
        config.muc_domain = "conf.hipchat.com" if config.muc_domain.nil?
      end
    end

    Lita.register_adapter(:hipchat, HipChat)
  end
end
