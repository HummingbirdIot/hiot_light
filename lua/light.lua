local lightGW = {}

local json = require("json")
local util = require("util")
local light_upgrade = require("light_upgrade")

function lightGW.GetMinerRegion()
  local info, succuess = util.shell('helium_gateway info -k region')
  if succuess then
    local data = json.decode(info)
    if data and data.region then return data.region end
  end
end

function lightGW.Stop()
  print("<<<< stop helium_gateway")
  if not os.execute("/etc/init.d/helium_gateway stop") then
    print("fail to stop helium gateway")
  end
end

function lightGW.Start()
  light_upgrade.Run(lightGW.Stop)
  print(">>>> Start helium_gateway")
  if not os.execute("/etc/init.d/helium_gateway start") then
    print("fail to start helium gateway")
  end
end

if ... then
  return lightGW
else
  lightGW.Start()
end
