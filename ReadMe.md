# itchy

A super simple version checker for use with [LÖVE](https://love2d.org) games
published on [itch.io](https://itch.io/).

## Installation

Just copy `check.lua` to where you want in your source.

## Usage

Start it in its own thread, and send a table on the "send-itchy" channel with
information on what you're looking for.

```lua
-- initialize
versionCheck = love.thread.newThread("lib/itchy/check.lua")
versionCheckSend = thread.getChannel("send-itchy")
versionCheck:start()
versionCheckSend:push({
  target = "guard13007/asteroid-dodge"
  -- other options are available!!
})
-- receive info
versionCheckReceive = thread.getChannel("receive-itchy")
if versionCheckReceive:getCount() > 0 then
  -- this could be a version or an error message!
  latest_version = versionCheckReceive:demand()
end
```

### Options

* `url` (string) If you have a different URL to check for the latest version
  from, you can specify it here.
* `target` REQUIRED (string) The target string of your game on itch.io
  (username/game-slug)
* `channel` (string) If you do not specify the channel name to look for on
  itch.io, it will use `osx` for Mac OS / OS X, `win32` for Windows, `linux` for
  Linux, `android` for Android, `ios` for iOS, and if any other OS is returned
  by `love.system.getOS()` it will use that string as-is.
* `version` (any) Version of the game running right now.
* `proxy` (string) This library uses an [HTTP proxy](https://github.com/Guard13007/insecure-proxy)
  for the HTTPS call to itch.io's API. By default it uses `https://104.236.139.220:16343`
  which is a DigitalOcean VPS I own. If you'd rather use a different proxy
  server, you can specify it here.
* `interval` (number) If specified, a check for the latest version will happen
  again every `interval` seconds.
* `send_interval_errors` DEFAULT false (boolean) Whether or not checks happening
  on an interval will report errors.
