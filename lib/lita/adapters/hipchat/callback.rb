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
      end
    end
  end
end
