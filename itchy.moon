thread = (...) ->
  require "love.thread"
  require "love.timer"
  import thread, timer from love

  http = require "socket.http"
  ok, libcurl = pcall -> return require "luajit-request"
  unless ok
    ok, libcurl = pcall -> return require "lib.luajit-request"
    libcurl = nil unless ok

  request = (data) ->
    result = {}
    unless libcurl
      if data.luajit_request
        ok, libcurl = pcall -> return require data.luajit_request
        libcurl = nil unless ok
    if libcurl
      response = libcurl.send data.url or "https://api.itch.io/wharf/latest?target=#{data.target}&channel_name=#{data.channel}"
      result.body = response.body
      result.status = response.code
    else
      unless data.proxy
        result.message = "Could not load libcurl."
        return nil, result
      result.body, result.status = http.request data.url or "#{data.proxy}/get/https://api.itch.io/wharf/latest?target=#{data.target}&channel_name=#{data.channel}"
      unless result.body
        result.message = "socket.http.request error: #{result.status}"
        result.status = nil
        return nil, result
    return true, result

  check = (data) ->
    send = thread.getChannel data.thread_channel or "itchy"

    exponential_backoff = 1
    while true
      result = {}
      unless data.url or data.target
        result.message = "'target' or 'url' be must be defined!"
        send\push result
        return false
      ok, result = request data

      unless ok
        send\push result
        return false

      result.version = result.body\match '%s*{%s*"latest"%s*:%s*"(.+)"%s*}%s*'
      result.version = tonumber(result.version) or result.version
      result.latest = if data.version
        result.version == data.version

      if result.status != 200 and (not result.version)
        result.message = "unknown, error getting latest version: HTTP #{result.status}, trying again in #{exponential_backoff} seconds..."
        send\push result
        timer.sleep exponential_backoff
        exponential_backoff *= 2
        exponential_backoff = 10 * 60 if exponential_backoff > 10 * 60 -- maximum backoff is 10 minutes
        continue
      elseif result.latest != nil
        if result.latest
          result.message = "#{result.version}, you have the latest vesion"
        else
          result.message = "#{result.version}, there is a newer version available!"
      else
        result.message = result.version

      send\push result
      return true

  -- data should be a table of information
  start = (data) ->
    data.proxy = "http://45.55.113.149:16343" if data.proxy == nil and (not data.url)

    -- channel can be autodetected if not specified
    unless data.channel
      require "love.system"
      os = love.system.getOS!
      switch os
        when "OS X"
          data.channel = "osx"
        when "Windows"
          data.channel = "win32"
        when "Linux"
          data.channel = "linux"
        when "Android"
          data.channel = "android"
        when "iOS"
          data.channel = "ios"
        else
          data.channel = os

    check data

    -- if we should check again every x seconds, wait, and do so
    if data.interval
      while true
        timer.sleep data.interval
        check data

  start(...)

-- detect if we are running in a thread, run directly if we are
return thread(...) unless love.graphics or love.window

thread_data = love.filesystem.newFileData string.dump(thread), "itchy version checker"

counter = 1
configs, results = {}, {}
local default_data

itchy = {
  check_version: (data) =>
    default_data = data unless default_data
    if (not data.thread_channel) and next configs
      data.thread_channel = "itchy-#{counter}"
      counter += 1
    configs[data] = data
    love.thread.newThread(thread_data)\start data
  new_version: (data=default_data) =>
    if data and configs[data]
      channel = love.thread.getChannel data.thread_channel or "itchy"
      if channel\getCount! > 0
        results[data] = channel\demand!
      return results[data] -- nil or data (new or old)
  kill_version_checker: (data=default_data) =>
    configs[data] = nil
    results[data] = nil
    default_data = nil if data == default_data
    -- we don't kill the thread, as that can crash the game
}

return itchy
