local light_upgrade = {}

local file = require("file")
local util = require("util")
local json = require("json")

local function GetCurrentVersion()
  local info, success = util.shell("helium_gateway -V | cut -d ' ' -f 2")
  if success then
    return util.trim(info)
  end
  return "unknown"
end

local function GetUpstreamVersion()
  local version = file.read(".helium-gateway-version")
  return util.trim(version)
end

local ReleaseTable = {
  aarch64 = "raspi_64.deb",
  mips = "clodpi.ipk",
  arm64 = "raspi_64.deb" -- for test
}

local function GetReleaseFile(version, arch)
  return "helium-gateway-v" .. version .. "-" .. ReleaseTable[arch]
end

local function GetArch()
  local info, success = util.shell("uname -m")
  if success then
    return util.trim(info)
  end
  return "aarch64"
end

local function UpgradeAndInstall(version, fileName)
  local url = "https://github.com/helium/gateway-rs/releases/download/v" .. version .. "/" .. fileName
  if file.exists(".proxyconf") then
    local info = json.decode(file.read(".proxyconf"))
    if info.releaseFileProxy.type == "urlPrefix" then
      url = info.releaseFileProxy.value .. url
    end
  end
  local tmpFile = "/tmp/light_gw" .. os.date("!%H%M%S") .. ".deb"
  local cmd = "wget -O " .. tmpFile .. " " .. url .. " && opkg install " .. tmpFile
  print(cmd)
  if not os.execute(cmd) then
    print("Fail to download deb and install")
  end
end

function light_upgrade.Run(callback)
  print(">>>> check helium_gateway updated")
  local upStreamVersion = GetUpstreamVersion()
  if upStreamVersion ~= GetCurrentVersion() then
    if callback ~= nil then callback() end
    local fileName = GetReleaseFile(upStreamVersion, GetArch())
    UpgradeAndInstall(upStreamVersion, fileName)
  end
end

if ... then
  return light_upgrade
else
  light_upgrade.Run()
end
