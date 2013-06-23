require "xmpp4r"
require "xmpp4r/roster/helper/roster"

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

        def load_roster
          @roster = Jabber::Roster::Helper.new(client)
          roster.wait_for_roster
        end
      end
    end
  end
end
