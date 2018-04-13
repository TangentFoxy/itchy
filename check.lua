require("love.timer")
local thread, timer
do
  local _obj_0 = love
  thread, timer = _obj_0.thread, _obj_0.timer
end
local http = require("socket.http")
local check
check = function(data)
  local send = thread.getChannel(data.thread_channel or "itchy")
  local exponential_backoff = 1
  while true do
    local _continue_0 = false
    repeat
      do
        local result = { }
        if data.url then
          result.body, result.status = http.request(data.url)
        elseif data.proxy then
          if not (data.target) then
            result.message = "'target' or 'url' must be defined!"
            send:push(result)
            return false
          end
          result.body, result.status = http.request(tostring(data.proxy) .. "/get/https://itch.io/api/1/x/wharf/latest?target=" .. tostring(data.target) .. "&channel_name=" .. tostring(data.channel))
        end
        if not (result.body) then
          result.message = "socket.http.request error: " .. tostring(result.status)
          send:push(result)
          return false
        end
        result.version = result.body:match('%s*{%s*"latest"%s*:%s*"(.+)"%s*}%s*')
        result.version = tonumber(result.version) or result.version
        if data.version then
          result.latest = result.version == data.version
        end
        if result.status ~= 200 and (not result.version) then
          result.message = "unknown, error getting latest version: HTTP " .. tostring(result.status) .. ", trying again in " .. tostring(exponential_backoff) .. " seconds"
          send:push(result)
          timer.sleep(exponential_backoff)
          exponential_backoff = exponential_backoff * 2
          if exponential_backoff > 10 * 60 then
            exponential_backoff = 10 * 60
          end
          _continue_0 = true
          break
        elseif result.latest ~= nil then
          if result.latest then
            result.message = tostring(result.version) .. ", you have the latest version"
          else
            result.message = tostring(result.version) .. ", there is a newer version available!"
          end
        else
          result.message = result.version
        end
        send:push(result)
        return true
      end
      _continue_0 = true
    until true
    if not _continue_0 then
      break
    end
  end
end
local start
start = function(data)
  if not (data.proxy or data.url) then
    data.proxy = "http://45.55.113.149:16343"
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
      check(data)
    end
  end
end
return start(...)
