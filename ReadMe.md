# itchy

A super simple version checker for use with [LÖVE](https://love2d.org) games
published on [itch.io](https://itch.io/).

## Installation

Just copy `check.lua` to where you want in your source.

## Usage

Start it in its own thread, and send a table on the "send-itchy" channel with
information on what you're looking for. Wait for a response on the
"receive-itchy" channel.

```lua
-- initialize
versionCheck = love.thread.newThread("lib/itchy/check.lua")
versionCheckSend = thread.getChannel("send-itchy")
versionCheck:start()
versionCheckSend:push({
  target = "guard13007/asteroid-dodge", -- target/url must be defined, see Options
  version = current_version             -- defined elsewhere (also, optional)
  -- other options are available!! see list below
})
-- receive info
versionCheckReceive = thread.getChannel("receive-itchy")
if versionCheckReceive:getCount() > 0 then
  data = versionCheckReceive:demand() -- this is a table of info, format specified below
  -- easiest usage is to just print something like this to the user somewhere
  print("Version: " .. current_version .. " Latest version: " .. data.message)
end
```

Returned data example:

```lua
{
  status = 200,                -- nil or status code of an HTTP request
  body = '{"latest":"0.2.0"}', -- raw resulting body from the HTTP request
  version = "0.2.0",           -- a number or string
  latest = true,               -- nil or boolean your version == latest version?
  message = "0.2.0, you have the latest version"   -- an error or status message
}
```

Errors from LuaSocket will be returned as `"socket.http.request error: " .. err`

The library tries to parse a response body for valid JSON of the format
`{"latest":"VERSION"}` (itch.io's format) and will do basic version comparisons
based on this value. If it is unable to extract it or compare, `version` and
`latest` will be `nil`.

If HTTP status 200 (OK) is encountered or a version is successfully parsed from
a response, the script terminates (or moves on to checking on an `interval`.)
Otherwise, it will keep trying with an exponential back-off starting at a 1
second delay.

### Options

At minimum a `url` or `target` must be specified.

* `url` (string) If you have a different URL to check for the latest version
  from, you can specify it here.
* `target` (string) The target string of your game on itch.io
  (username/game-slug)
* `channel` (string) If you do not specify the channel name to look for on
  itch.io, it will use `osx` for Mac OS / OS X, `win32` for Windows, `linux` for
  Linux, `android` for Android, `ios` for iOS, and if any other OS is returned
  by `love.system.getOS()` it will use that string as-is.
* `version` (string/number) Version of the game running right now.
* `proxy` (string) This library uses an [HTTP proxy](https://github.com/Guard13007/insecure-proxy)
  for the HTTPS call to itch.io's API. By default it uses `https://104.236.139.220:16343`
  which is a DigitalOcean VPS I own. If you'd rather use a different proxy
  server, you can specify it here.
* `interval` (number) If specified, a check for the latest version will happen
  again every `interval` seconds.
