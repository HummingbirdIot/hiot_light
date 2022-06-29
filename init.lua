local PWD = os.getenv("PWD")
print('in init.lua')
if PWD then
  package.path = PWD .. "/lua/?.lua;" .. package.path
end

local file = require("file")
local util = require("util")

local hiot = require('hummingbird_iot')
if arg[1] ~= nil and arg[1] == "timer" then
  math.randomseed(os.time())
  local t = math.random(1,500)
  print("hiot timer trigger " .. tostring(t))
  local dateStr = os.date("%m/%d/%Y %I:%M %p");
  file.write("/tmp/hiot_light.log", dateStr);
  util.sleep(t)
end

hiot.Run()
