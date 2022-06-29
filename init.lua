local PWD = os.getenv("PWD")
print('in init.lua')
if PWD then
  package.path = PWD .. "/lua/?.lua;" .. package.path
end

local file = require("file")
local util = require("util")

local pidFile = "/tmp/hiot_light.run"

local hiot = require('hummingbird_iot')
if arg[1] ~= nil and arg[1] == "timer" then
  math.randomseed(os.time())
  local t = math.random(1,500)
  print("hiot timer trigger " .. tostring(t))
  util.sleep(t)
end

if file.exists(pidFile) then print("hiot_light is running just exit") end
file.write(pidFile, "running")

hiot.Run()
file.remove(pidFile)
