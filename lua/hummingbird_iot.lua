local hiot = {RuntimeConfig = {}}

local file = require("file")
local util = require("util")

local undefined_region = "undefined"

hiot.loraRegions = {
  region_cn470 = {name = "region_cn470", pkt_fwd = "hnt-pkt-fwd-cn470"},
  region_eu868 = {name = "region_eu868", pkt_fwd = "hnt-pkt-fwd-eu868"},
  region_us915 = {name = "region_us915", pkt_fwd = "hnt-pkt-fwd-us915"}
}

function hiot.GetDefaultLoraRegion()
  if hiot.RuntimeConfig ~= nil and hiot.RuntimeConfig.region ~= undefined_region then
    return hiot.RuntimeConfig.region
  end
  return hiot.loraRegions.region_cn470.name
end

local function GetCurrentLuaFile()
  local source = debug.getinfo(2, "S").source
  if source:sub(1, 1) == "@" then
    return source:sub(2)
  else
    error("Caller was not defined in a file", 2)
  end
end

local function PatchTargetFile(Src, Dest)
  local cmd = "diff " .. Src .. " " .. Dest
  if file.exists(Src) then
    print(cmd)
    if not os.execute(cmd) then
      return os.execute("cp " .. Src .. " " .. Dest)
    end
  else
    print("!!! error:" .. Src .. " or " .. Dest .. "Not Exist just ingore")
  end
  return false
end

local function PatchServices(services)
  for _, v in pairs(services) do
    print("check for " .. v.name)
    if PatchTargetFile(v.src, v.dest) and v.action then
      if not os.execute(v.action) then
        print("failed do post action " .. v.action .. " for " .. v.name)
      end
    end
  end
end

function hiot.Run()
  print(">>>>> hummingbirdiot start <<<<<<")
  if not file.exists(".proxyconf") then
    file.copy("./config/proxy.conf", ".proxyconf")
  end

  hiot.RuntimeConfig = util.loadFileToTable("/etc/hummingbird_iot.config")

  print(GetCurrentLuaFile())
  util.tryWaitNetwork()
  util.patchGit()
  util.gitSetup()
  local light = require("light")
  util.syncToUpstream(
    false,
    function()
      light.Stop()
    end
  )
  light.Start()
end

if ... then
  return hiot
else
  hiot.Run()
end
