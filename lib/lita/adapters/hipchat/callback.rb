module Lita
  module Adapters
    class HipChat < Adapter
      class Callback
        attr_reader :robot, :roster

        def initialize(robot, roster)
          @robot = robot
          @roster = roster
        end

        def private_message(client)
          client.add_message_callback do |m|
            next if m.type == :error
            user = user_by_jid(m.from)
            source = Source.new(user)
            message = Message.new(robot, m.body, source)
            message.command!
            robot.receive(message)
          end
        end

        def muc_message(muc)
          muc.on_message do |time, nick, text|
            user = user_by_name(nick)
            source = Source.new(user, muc.jid.bare.to_s)
            message = Message.new(robot, text, source)
            robot.receive(message)
          end
        end

        private

        def user_by_jid(jid)
          user_data = roster[jid].attributes

          User.create(
            user_data["jid"],
            name: user_data["name"],
            mention_name: user_data["mention_name"]
          )
        end

        def user_by_name(name)
          jid = roster.items.detect { |jid, item| item.iname == name }.first
          user_by_jid(jid)
        end
      end
    end
  end
end
