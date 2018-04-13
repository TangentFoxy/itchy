versionChecker = love.thread.newThread("lib/itchy/check.lua") -- wherever you save it..
versionChecker:start({
  target = "guard13007/asteroid-dodge", -- target/url must be defined
  version = "1.0.0"                     -- optional
})

newVersion = love.thread.getChannel("itchy")
if newVersion:getCount() > 0 then
  local data = newVersion:demand()
  -- easiest usage is to just print something like this to the user
  print("Version: 1.0.0 Latest version: " .. data.message)
end
