# itchy

A super simple version checker for use with [LÖVE](https://love2d.org) games
published on [itch.io](https://itch.io/).

## Installation

Just copy `check.lua` to where you want in your source.

## Usage

Start it as a thread with a configuration table. Wait for "itchy" channel to
respond with a table of version information.

```lua
versionChecker = love.thread.newThread("lib/itchy/check.lua") -- wherever you save it..
versionChecker:start({
  target = "guard13007/asteroid-dodge", -- target/url must be defined
  version = "1.0.0"                     -- optional, config options listed below
})

newVersion = love.thread.getChannel("itchy")
if newVersion:getCount() > 0 then
  local data = newVersion:demand() -- see example data below
  -- easiest usage is to just print something like this to the user
  print("Version: 1.0.0 Latest version: " .. data.message)
end
```

Since it is run as a thread, you can cancel it with `versionChecker:kill()` and
start it again or with a different configuration later with `:start()`.

### Version Information Example

Returned data example:

```lua
{
  status = 200,                -- nil or status code of an HTTP request
  body = '{"latest":"0.2.0"}', -- raw result body from the HTTP request
  version = "0.2.0",           -- number/string (if body was parsed correctly)
  latest = true,               -- nil/boolean: your version == latest version?
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
second delay, capped at retrying every 10 minutes.

### Configuration Options

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
  which is on a DigitalOcean VPS I own. If you'd rather use a different proxy
  server, you can specify it here.
* `interval` (number) If specified, a check for the latest version will happen
  again every `interval` seconds.
* `thread_channel` (string) If specified, will use a different named thread
  channel to return results to.
