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

local function green_led_on(isOn)
  if isOn then
    os.execute('gpioset 1 9=1')
  else
    os.execute('gpioset 1 9=0')
  end
end

local function red_led_on(isOn)
  if isOn then
    os.execute('gpioset 1 8=1')
  else
    os.execute('gpioset 1 8=0')
  end
end

function lightGW.Start()
  green_led_on(false)
  red_led_on(true)
  light_upgrade.Run(lightGW.Stop)
  print(">>>> Start helium_gateway")
  if not os.execute("/etc/init.d/helium_gateway start") then
    print("fail to start helium gateway")
  end
  red_led_on(false)
  green_led_on(true)
end

if ... then
  return lightGW
else
  lightGW.Start()
end
