require "lita"
require "lita/rexml"

require "xmpp4r"
require "xmpp4r/muc/helper/simplemucclient"
require "xmpp4r/roster/helper/roster"
require "xmpp4r/muc/helper/mucbrowser"

module Lita
  module Adapters
    class HipChat < Adapter
      require_configs :jid, :password

      def initialize(robot)
        super

        Jabber.debug = true if Lita.config.adapter.debug

        jid = Jabber::JID.new(Lita.config.adapter.jid)
        jid.resource = "bot"
        @client = Jabber::Client.new(jid)
      end

      def run
        connect
        join_rooms
        sleep
      end

      def send_messages(source, strings)
        if source.room
          muc = @mucs[source.room]
          strings.each { |s| muc.say(s) }
        else
          strings.each do |s|
            message = Jabber::Message.new(source.user.id, s)
            message.type = :chat
            @client.send(message)
          end
        end
      end

      private

      def connect
        @client.connect
        @client.auth(Lita.config.adapter.password)
        @client.send(Jabber::Presence.new(:chat))

        register_message_callback

        @roster = Jabber::Roster::Helper.new(@client)
        @roster.wait_for_roster

        @browser = Jabber::MUC::MUCBrowser.new(@client)
      end

      def register_message_callback
        @client.add_message_callback do |m|
          next if m.body.nil?
          user = user_by_jid(m.from)
          source = Source.new(user)
          message = Message.new(robot, m.body, source)
          message.command!
          robot.receive(message)
        end
      end

      def join_rooms
        rooms = determine_rooms
        return unless rooms
        @mucs = {}
        rooms.each do |room_name|
          muc = Jabber::MUC::SimpleMUCClient.new(@client)
          register_room_message_callback(muc)
          room_jid = Jabber::JID.new("#{room_name}/#{robot.name}")
          muc.join(room_jid)

          @mucs[muc.jid.bare.to_s] = muc
        end
      end

      def determine_rooms
        rooms = Lita.config.adapter.rooms
        domain = Lita.config.adapter.muc_domain || "conf.hipchat.com"
        return unless domain && rooms

        if rooms == :all
          rooms = @browser.muc_rooms(domain).map { |jid, name| jid.to_s }
        end

        Array(rooms)
      end

      def register_room_message_callback(muc)
        muc.on_message do |time, nick, text|
          next if muc.nick == nick
          user = user_by_nick(nick)
          source = Source.new(user, muc.jid.bare.to_s)
          message = Message.new(robot, text, source)
          robot.receive(message)
        end
      end

      def user_by_nick(nick)
        jid = @roster.items.detect do |jid, item|
          item.iname == nick
        end.first

        user_by_jid(jid)
      end

      def user_by_jid(jid)
        user_data = @roster[jid].attributes

        User.create(
          user_data["jid"],
          name: user_data["name"],
          mention_name: user_data["mention_name"]
        )
      end
    end

    Lita.register_adapter(:hipchat, HipChat)
  end
end
