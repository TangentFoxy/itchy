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
