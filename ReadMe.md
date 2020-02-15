# itchy

A super simple version checker for use with [LÖVE](https://love2d.org) games
published on [itch.io](https://itch.io/).

## Installation

Copy `itchy.lua` to where you want in your source. It is recommended that you
install [luajit-request](https://github.com/LPGhatguy/luajit-request) as it
allows for itchy to use HTTPS connections.

luajit-request on Windows requires a libcurl DLL to be alongside the executable
of a fused game, or in the root-level source directory for an unfused game. You
can find them [here](https://curl.haxx.se/download.html). On Mac OS, this should
be already installed, and most Linux distributions have it installed already.
Please tell your Linux users to install libcurl if they do not have it and you
are relying on its functionality.

(I don't remember which of these is which, but I have verified
[this DLL](https://mega.nz/#!EMVA3brL!7D8rycffbEU2qem6N_JTeuZOdwGwOl-zp3Z3wgGpKXQ)
works for 32-bit builds, and
[this DLL](https://mega.nz/#!5Md0jbBK!9KpcPQnN0hVtYd5_OzjNoQWf5wFJ7rG7SfPuSaMMQCU)
is the 64-bit version of it.)

## Usage

Start it as a thread with a configuration table. Wait for "itchy" channel to
respond with a table of version information.

Require itchy, and run `check_version` with a configuration table. Periodically
run `new_version` to see if data has been returned yet.

```lua
local itchy = require "lib.itchy"       -- or wherever you saved it
local game = {
  target = "guard13007/asteroid-dodge", -- target or url must be defined
  version = "1.0.0"                     -- optional, config options listed below
}
itchy:check_version(game)

-- somewhere where this will be called periodically
local data = itchy:new_version(game)  -- passing the game table is not necessary
if data then
  -- easiest usage, just print the message to the user
  love.graphics.print("Version: 1.0.0 Latest: " .. data.message)
end
```

You can cancel it with `itchy:kill_version_checker(game)`, and start a new
version checker with `itchy:check_version({})` any time you like.

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
a response, the script terminates (or moves on to checking on an interval.)
Otherwise, it will keep trying with an exponential back-off starting at a 1
second delay, capped at retrying every 10 minutes.

### Configuration Options

At minimum a `url` or `target` must be specified.

* `url` (string) If you have a different URL to check for the latest version
  from, you can specify it here.
* `target` (string) The target string of your game on itch.io
  (username/game-slug).
* `channel` (string) If you do not specify the channel name to look for on
  itch.io, it will use `osx` for Mac OS / OS X, `win32` for Windows, `linux` for
  Linux, `android` for Android, `ios` for iOS, and if any other OS is returned
  by `love.system.getOS()` it will use that string as-is.
* `version` (string/number) Version of the game running right now.
* `interval` (number) If specified, a check for the latest version will happen
  again every `interval` seconds.
* `luajit_request` (string) luajit-request is checked for in `.` and `lib/.`, if
  you have it elsewhere, specify its location here.

The following options are available, but generally should be left for itchy to
handle itself:

* `proxy` (string) An [HTTP proxy](https://github.com/Guard13007/insecure-proxy)
  is used if luajit-request is unavailable, unless `proxy == false`. By default,
  `http://insecure-proxy.tangentfox.com` is used. You can specify a different
  proxy here.
* `thread_channel` (string) itchy uses a channel named `itchy` for version
  checking. You can call itchy's functions with different data tables and it
  will use different threads & channels for each. You can also specify a channel
  name here.
