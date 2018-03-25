require("love.timer")
local thread, timer
do
  local _obj_0 = love
  thread, timer = _obj_0.thread, _obj_0.timer
end
local http = require("socket.http")
local receive = thread.getChannel("send-itchy")
local send = thread.getChannel("receive-itchy")
local check
check = function(data, send_errors)
  if send_errors == nil then
    send_errors = true
  end
  local exponential_backoff = 1
  while true do
    local body, status
    if data.url then
      body, status = http.request(data.url)
    elseif data.proxy then
      body, status = http.request(tostring(data.proxy) .. "/get/https://itch.io/api/1/x/wharf/latest?target=" .. tostring(data.target) .. "&channel_name=" .. tostring(data.channel))
    end
    if status == 200 then
      local latest = body:match('%s*{%s*"latest"%s*:%s*"(.+)"%s*}%s*')
      send:push(latest)
      return true
    else
      if send_errors then
        send:push("unknown, error getting latest version: HTTP " .. tostring(status) .. ", trying again in " .. tostring(exponential_backoff) .. " seconds")
      end
      timer.sleep(exponential_backoff)
      exponential_backoff = exponential_backoff * 2
    end
  end
end
local start
start = function()
  local data = receive:demand()
  if not (data.target) then
    error("Target undefined. Cannot search for latest version of unknown target!")
  end
  if not (data.version) then
    data.version = "0"
  end
  if not (data.proxy or data.url) then
    data.proxy = "http://104.236.139.220:16343"
  end
  if not (data.channel) then
    require("love.system")
    local os = love.system.getOS()
    local _exp_0 = os
    if "OS X" == _exp_0 then
      data.channel = "osx"
    elseif "Windows" == _exp_0 then
      data.channel = "win32"
    elseif "Linux" == _exp_0 then
      data.channel = "linux"
    elseif "Android" == _exp_0 then
      data.channel = "android"
    elseif "iOS" == _exp_0 then
      data.channel = "ios"
    else
      data.channel = os
    end
  end
  check(data)
  if data.interval then
    while true do
      timer.sleep(data.interval)
      if receive:getCount() > 0 then
        return start()
      end
      check(data, data.send_interval_errors)
    end
  end
end
return start()
