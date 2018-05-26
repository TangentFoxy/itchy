local thread
thread = function(...)
  require("love.thread")
  require("love.timer")
  local timer
  do
    local _obj_0 = love
    thread, timer = _obj_0.thread, _obj_0.timer
  end
  local http = require("socket.http")
  local ok, libcurl = pcall(function()
    return require("luajit-request")
  end)
  if not (ok) then
    ok, libcurl = pcall(function()
      return require("lib.luajit-request")
    end)
    if not (ok) then
      libcurl = nil
    end
  end
  local request
  request = function(data)
    local result = { }
    if not (libcurl) then
      if data.luajit_request then
        ok, libcurl = pcall(function()
          return require(data.luajit_request)
        end)
        if not (ok) then
          libcurl = nil
        end
      end
    end
    if libcurl then
      local response = libcurl.send(data.url or "https://api.itch.io/wharf/latest?target=" .. tostring(data.target) .. "&channel_name=" .. tostring(data.channel))
      result.body = response.body
      result.status = response.code
    else
      if not (data.proxy) then
        result.message = "Could not load libcurl."
        return nil, result
      end
      result.body, result.status = http.request(data.url or tostring(data.proxy) .. "/get/https://api.itch.io/wharf/latest?target=" .. tostring(data.target) .. "&channel_name=" .. tostring(data.channel))
      if not (result.body) then
        result.message = "socket.http.request error: " .. tostring(result.status)
        result.status = nil
        return nil, result
      end
    end
    return true, result
  end
  local check
  check = function(data)
    local send = thread.getChannel(data.thread_channel or "itchy")
    local exponential_backoff = 1
    while true do
      local _continue_0 = false
      repeat
        do
          local result = { }
          if not (data.url or data.target) then
            result.message = "'target' or 'url' be must be defined!"
            send:push(result)
            return false
          end
          ok, result = request(data)
          if not (ok) then
            send:push(result)
            return false
          end
          result.version = result.body:match('%s*{%s*"latest"%s*:%s*"(.+)"%s*}%s*')
          result.version = tonumber(result.version) or result.version
          if data.version then
            result.latest = result.version == data.version
          end
          if result.status ~= 200 and (not result.version) then
            result.message = "unknown, error getting latest version: HTTP " .. tostring(result.status) .. ", trying again in " .. tostring(exponential_backoff) .. " seconds..."
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
              result.message = tostring(result.version) .. ", you have the latest vesion"
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
    if data.proxy == nil and (not data.url) then
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
end
if not (love.graphics or love.window) then
  return thread(...)
end
local thread_data = love.filesystem.newFileData(string.dump(thread), "itchy version checker")
local counter = 1
local configs, results = { }, { }
local default_data
local itchy = {
  check_version = function(self, data)
    if not (default_data) then
      default_data = data
    end
    if (not data.thread_channel) and next(configs) then
      data.thread_channel = "itchy-" .. tostring(counter)
      counter = counter + 1
    end
    configs[data] = data
    return love.thread.newThread(thread_data):start(data)
  end,
  new_version = function(self, data)
    if data == nil then
      data = default_data
    end
    if data and configs[data] then
      local channel = love.thread.getChannel(data.thread_channel or "itchy")
      if channel:getCount() > 0 then
        results[data] = channel:demand()
      end
      return results[data]
    end
  end,
  kill_version_checker = function(self, data)
    if data == nil then
      data = default_data
    end
    configs[data] = nil
    results[data] = nil
    if data == default_data then
      default_data = nil
    end
  end
}
return itchy
