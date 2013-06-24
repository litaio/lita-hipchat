# lita-hipchat

[![Build Status](https://travis-ci.org/jimmycuadra/lita-hipchat.png)](https://travis-ci.org/jimmycuadra/lita-hipchat)
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

* `debug` (Boolean) - If `true`, turns on the underlying Jabber library's (xmpp4r) logger, which is fairly verbose. Default: `false`.
* `rooms` (Symbol, Array<String>) - An array of room JIDs that Lita should join upon connection. Can also be the symbol `:all`, which will cause Lita to discover and join all rooms. Default: `nil` (no rooms).
* `muc_domain` (String) - The XMPP Multi-User Chat domain to use. Default: `"conf.hipchat.com"`.

**Note: You must set the robot's name to the value shown as "Room nickname" on the XMPP settings page.**

There's no need to set `config.robot.mention_name` manually. The adapter will load the proper mention name from the XMPP roster upon connection.

### Example

``` ruby
Lita.configure do |config|
  config.robot.name = "Lita Bot"
  config.robot.adapter = :hipchat
  config.adapter.jid = "12345_123456@chat.hipchat.com"
  config.adapter.password = "secret"
  config.adapter.debug = false
  config.adapter.rooms = :all
  config.adapter.muc_domain = "conf.hipchat.com"
end
```

## License

[MIT](http://opensource.org/licenses/MIT)
