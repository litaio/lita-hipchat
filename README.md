# lita-hipchat

[![Build Status](https://travis-ci.org/jimmycuadra/lita-hipchat.png?branch=master)](https://travis-ci.org/jimmycuadra/lita-hipchat)
[![Code Climate](https://codeclimate.com/github/jimmycuadra/lita-hipchat.png)](https://codeclimate.com/github/jimmycuadra/lita-hipchat)
[![Coverage Status](https://coveralls.io/repos/jimmycuadra/lita-hipchat/badge.png)](https://coveralls.io/r/jimmycuadra/lita-hipchat)

**lita-hipchat** is an adapter for [Lita](https://github.com/jimmycuadra/lita) that allows you to use the robot with [HipChat](https://www.hipchat.com/).

## Installation

Add lita-hipchat to your Lita instance's Gemfile:

``` ruby
gem "lita-hipchat"
```

## Configuration

Values for all of the following attributes can be found on the "XMPP/Jabber info" page of the account settings on the HipChat website. A JID (Jabber ID) looks like "12345_123456@chat.hipchat.com".

### Required attributes

* `jid` (String) - The JID of your robot's HipChat account. Default: `nil`.
* `password` (String) - The password for your robot's HipChat account. Default: `nil`.

### Optional attributes

* `server` (String) - The HipChat Server address. Override this with the full domain of your server if using a private HipChat Server installation. Default: `"chat.hipchat.com"`
* `debug` (Boolean) - If `true`, turns on the underlying Jabber library's (xmpp4r) logger, which is fairly verbose. Default: `false`.
* **DEPRECATED** - `rooms` (Symbol, Array<String>) - An array of room JIDs that Lita should join upon connection. Can also be the symbol `:all`, which will cause Lita to discover and join all rooms. Default: `nil` (no rooms).
* `muc_domain` (String) - The XMPP Multi-User Chat domain to use. Default: `"conf.hipchat.com"`.
* `ignore_unknown_users` (Boolean) - Messages generated through HipChat's API which don't come from a real user account will be ignored by the robot. With the default setting of false, Lita will emit a warning but the message will be dispatched to any registered handlers as usual. Default: `false`.

**Note: You must set the robot's name to the value shown as "Room nickname" on the XMPP settings page.**

There's no need to set `config.robot.mention_name` manually. The adapter will load the proper mention name from the XMPP roster upon connection.

### Example

``` ruby
Lita.configure do |config|
  config.robot.name = "Lita Bot"
  config.robot.adapter = :hipchat
  config.adapters.hipchat.jid = "12345_123456@chat.hipchat.com"
  config.adapters.hipchat.password = "secret"
  config.adapters.hipchat.debug = true
  config.adapters.hipchat.rooms = :all
end
```

## Events

`:connected` - When the robot has connected to HipChat. No payload.
`:disconnected` - When the robot has disconnected from HipChat. No payload.
`:joined` - When the robot joins a room. Payload: `:room`: The String room ID that was joined.
`:parted` - When the robot parts from a room. Payload: `:room`: The String room ID that was parted from.

## Managing rooms

To make Lita join or part from rooms, use the [built-in `join` and `part` commands](http://docs.lita.io/getting-started/usage/#managing-rooms). For backwards compatibility, the `rooms` configuration attribute will be supported until lita-hipchat 4.0, but you should remove it and begin using the new command instead. If the configuration attribute is set, lita-hipchat will honor its value and join those rooms instead of the ones persisted to Redis from using the new commands.

## License

[MIT](http://opensource.org/licenses/MIT)
