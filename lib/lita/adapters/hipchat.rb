require "lita"
require "lita/rexml"
require "xmpp4r"
require "xmpp4r/muc"
require "lita/mucclient"

Jabber.debug = true

Lita.configure do |config|
  config.adapter.rooms = :all
end

module Lita
  module Adapters
    class HipChat < Adapter
      require_configs :jid, :password

      def run
        @jid = Jabber::JID.new(Lita.config.adapter.jid)
        @client = Jabber::Client.new(@jid)
        @browser = Jabber::MUC::MUCBrowser.new(@client)
        @mucs = []

        register_message_callback
        connect
        join_rooms

        sleep
      end

      def send_messages(source, strings)
        target, type = if source.room
          [source.room, :groupchat]
        else
          [source.user, :chat]
        end

        strings.each do |string|
          message = Jabber::Message.new(target, string)
          message.type = type
          @client.send(message)
        end
      end

      private

      def register_message_callback
        @client.add_message_callback do |m|
          next if m.body.nil?

          source = Source.new(m.from)
          message = Message.new(robot, m.body, source)
          message.command!
          robot.receive(message)
        end
      end

      def connect
        @client.connect
        @client.auth(Lita.config.adapter.password)
        @client.send(Jabber::Presence.new(:chat))
      end

      def join_rooms
        rooms = determine_rooms
        return unless rooms

        rooms.each do |room|
          muc = Jabber::MUC::SimpleMUCClient.new(@client)

          muc.on_message do |time, nick, text|
            next if muc.nick == nick

            user = muc.roster[nick].from
            source = Source.new(user, muc.jid)
            message = Message.new(robot, text, source)
            robot.receive(message)
          end

          room_jid = Jabber::JID.new("#{room}/#{robot.name}")
          muc.join(room_jid, nil, history: false)

          @mucs << muc
        end
      end

      def determine_rooms
        rooms = Lita.config.adapter.rooms
        domain = Lita.config.adapter.muc_domain
        return unless domain

        if rooms == :all
          rooms = @browser.muc_rooms(domain).map { |jid, name| jid }
        end

        Array(rooms)
      end
    end

    Lita.register_adapter(:hipchat, HipChat)
  end
end
