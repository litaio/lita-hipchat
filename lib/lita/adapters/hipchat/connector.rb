require "xmpp4r"
require "xmpp4r/roster/helper/roster"
require "xmpp4r/muc/helper/simplemucclient"

module Lita
  module Adapters
    class HipChat < Adapter
      class Connector
        attr_reader :client, :roster

        def initialize(jid, password, debug: false)
          @jid = Jabber::JID.new(jid)
          @jid.resource = "bot"

          unless @jid.node
            @jid.node = @jid.domain
            @jid.domain = "chat.hipchat.com"
          end

          @password = password
          @client = Jabber::Client.new(@jid)

          Jabber.debug = true if debug
        end

        def jid
          @jid.to_s
        end

        def connect
          client_connect
          register_message_callback
          load_roster
        end

        def join_rooms(muc_domain, rooms)
          rooms.each do |room_name|
            muc = Jabber::MUC::SimpleMUCClient.new(client)
            room_jid = Jabber::JID.new(room_name)
            room_jid.resource = robot_name
            unless room_jid.node
              room_jid.node = room_jid.domain
              room_jid.domain = muc_domain
            end
            mucs[room_jid.bare.to_s] = muc
            register_muc_message_callback(muc)
            muc.join(room_jid)
          end
        end

        def mucs
          @mucs ||= {}
        end

        def shut_down
          client.close
        end

        private

        def client_connect
          client.connect
          client.auth(@password)
          client.send(Jabber::Presence.new(:chat))
        end

        def register_message_callback
          client.add_message_callback do |m|
          end
        end

        def register_muc_message_callback(muc)
          muc.on_message do |time, nick, text|
          end
        end

        def load_roster
          @roster = Jabber::Roster::Helper.new(client)
          roster.wait_for_roster
        end

        def robot_name
          Lita.config.robot.name
        end
      end
    end
  end
end
