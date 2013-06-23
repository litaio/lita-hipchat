require "lita/encoding_patches"
require "lita/adapters/hipchat/callback"

require "xmpp4r"
require "xmpp4r/roster/helper/roster"
require "xmpp4r/muc/helper/simplemucclient"
require "xmpp4r/muc/helper/mucbrowser"

module Lita
  module Adapters
    class HipChat < Adapter
      class Connector
        attr_reader :robot, :client, :roster

        def initialize(robot, jid, password, debug: false)
          @robot = robot
          @jid = normalized_jid(jid, "chat.hipchat.com", "bot")
          @password = password
          @client = Jabber::Client.new(@jid)
          if debug
            Lita.logger.info("Enabling Jabber log.")
            Jabber.debug = true
          end
        end

        def jid
          @jid.to_s
        end

        def connect
          client_connect
          load_roster
          register_message_callback
          send_presence
        end

        def join_rooms(muc_domain, rooms)
          rooms.each do |room_name|
            muc = Jabber::MUC::SimpleMUCClient.new(client)
            room_jid = normalized_jid(room_name, muc_domain, robot.name)
            mucs[room_jid.bare.to_s] = muc
            register_muc_message_callback(muc)
            Lita.logger.info("Joining room: #{room_jid}.")
            muc.join(room_jid)
          end
        end

        def list_rooms(muc_domain)
          Lita.logger.debug("Querying server for list of rooms.")
          browser = Jabber::MUC::MUCBrowser.new(client)
          browser.muc_rooms(muc_domain).map { |jid, name| jid.to_s }
        end

        def message_jid(user_jid, strings)
          strings.each do |s|
            Lita.logger.debug("Sending message to JID #{user_jid}: #{s}")
            message = Jabber::Message.new(user_jid, s)
            message.type = :chat
            client.send(message)
          end
        end

        def message_muc(room_jid, strings)
          muc = mucs[room_jid]
          strings.each do |s|
            Lita.logger.debug("Sending message to MUC #{room_jid}: #{s}")
            muc.say(s)
          end if muc
        end

        def mucs
          @mucs ||= {}
        end

        def set_topic(room_jid, topic)
          muc = mucs[room_jid]
          if muc
            Lita.logger.debug("Setting topic for MUC #{room_jid}: #{topic}")
            muc.subject = topic
          end
        end

        def shut_down
          Lita.logger.info("Disconnecting from HipChat.")
          client.close
        end

        private

        def send_presence
          Lita.logger.debug("Sending initial XMPP presence.")
          client.send(Jabber::Presence.new(:chat))
        end

        def client_connect
          Lita.logger.info("Connecting to HipChat.")
          client.connect
          Lita.logger.debug("Authenticating with HipChat.")
          client.auth(@password)
        end

        def register_message_callback
          Callback.new(robot, roster).private_message(client)
        end

        def register_muc_message_callback(muc)
          Callback.new(robot, roster).muc_message(muc)
        end

        def load_roster
          Lita.logger.debug("Loading roster.")
          @roster = Jabber::Roster::Helper.new(client)
          roster.wait_for_roster
          robot.mention_name = roster[jid].attributes["mention_name"]
        end

        def normalized_jid(jid, domain, resource)
          jid = Jabber::JID.new(jid)
          jid.resource = resource
          unless jid.node
            jid.node = jid.domain
            jid.domain = domain
          end
          jid
        end
      end
    end
  end
end
