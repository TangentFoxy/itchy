require "love.timer"
import thread, timer from love

http = require "socket.http"
receive = thread.getChannel "send-itchy"
send = thread.getChannel "receive-itchy"

check = (data) ->
  exponential_backoff = 1
  while true
    result = {}
    if data.url
      result.body, result.status = http.request data.url
    elseif data.proxy
      unless data.target
        result.message = "'target' or 'url' must be defined!"
        send\push result
        return false
      result.body, result.status = http.request "#{data.proxy}/get/https://itch.io/api/1/x/wharf/latest?target=#{data.target}&channel_name=#{data.channel}"

    unless result.body
      result.message = "socket.http.request error: #{result.status}"
      send\push result
      return false

    result.version = result.body\match '%s*{%s*"latest"%s*:%s*"(.+)"%s*}%s*'
    result.version = tonumber(result.version) or result.version
    result.latest = if data.version
      result.version == data.version

    if result.status != 200 and (not result.version)
      result.message = "unknown, error getting latest version: HTTP #{result.status}, trying again in #{exponential_backoff} seconds"
      send\push result
      timer.sleep exponential_backoff
      exponential_backoff *= 2
      continue
    elseif result.latest != nil
      if result.latest
        result.message = "#{result.version}, you have the latest version"
      else
        result.message = "#{result.version}, there is a newer version available!"
    else
      result.message = result.version

    send\push result
    return true

start = ->
  -- data should be a table of information
  data = receive\demand!
  data.proxy = "http://45.55.113.149:16343" unless data.proxy or data.url

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

      -- if we are sent new data, start over entirely
      if receive\getCount! > 0
        return start!
      else
        check data

start!
