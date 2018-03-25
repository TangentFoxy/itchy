require "love.timer"
import thread, timer from love

http = require "socket.http"
receive = thread.getChannel "send-itchy"
send = thread.getChannel "receive-itchy"

check = (data, send_errors=true) ->
  exponential_backoff = 1
  while true
    local body, status
    if data.url
      body, status = http.request data.url
    elseif data.proxy
      body, status = http.request "#{data.proxy}/get/https://itch.io/api/1/x/wharf/latest?target=#{data.target}&channel_name=#{data.channel}"

    if status == 200
      latest = body\match '%s*{%s*"latest"%s*:%s*"(.+)"%s*}%s*'
      send\push latest
      return true
    else
      if send_errors
        send\push "unknown, error getting latest version: HTTP #{status}, trying again in #{exponential_backoff} seconds"
      timer.sleep exponential_backoff
      exponential_backoff = exponential_backoff * 2

start = ->
  -- data should be a table of information
  data = receive\demand!
  unless data.target
    error "Target undefined. Cannot search for latest version of unknown target!"

  data.version = "0" unless data.version
  data.proxy = "http://104.236.139.220:16343" unless data.proxy or data.url

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

      check data, data.send_interval_errors

start!
