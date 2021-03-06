local util = {}
--for relative module load
--local requireRel
--
----local selfPath = debug.getinfo(1,"S").source:sub(2)
--if ... then
--  local d = (...):match("(.-)[^%\\/]+$")
--  function requireRel(module)
--    return require(d .. module)
--  end
--elseif arg and arg[0] then
--  package.path = arg[0]:match("(.-)[^\\/]+$") .. "?.lua;" .. package.path
--  requireRel = require
--end

local file = require("file")

assert(file.exists)

local OTA_STATUS_FILE = "/tmp/hummingbird_ota"

function util.split(str, sep)
   local result = {}
   local regex = ("([^%s]+)"):format(sep)
   for each in str:gmatch(regex) do
      table.insert(result, each)
   end
   return result
end

function util.loadFileToTable(name)
  local ret = {}
  if not file.exists(name) then return ret end
  local content = file.read(name, "*a")
  local lines = util.split(content, "\n")
  for i=1, #lines do
    local info = util.split(lines[i], "=")
    if #info == 2 then ret[util.trim(info[1])] = util.trim(info[2]) end
  end
  return ret
end

function util.tableToString(info)
  local ret = ""
  for k,v in pairs(info) do
    if k then ret = ret .. util.trim(tostring(k)) .. "=" .. util.trim(tostring(v)) .. "\n" end
  end
  return ret
end

local function IsDarwin()
  return io.popen("uname -s", "r"):read("*l") == "Darwin"
end

function util.runAllcmd(cmds)
  for _, cmd in pairs(cmds) do
    if not os.execute(cmd) then
      print("fail to exec " .. cmd)
      return false
    end
  end
  return true
end

function util.trim(s)
  return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

function util.shell(cmd)
  local fileHandle = assert(io.popen(cmd, "r"))
  local commandOutput = assert(fileHandle:read("*a"))
  local success = fileHandle:close()
  return util.trim(commandOutput), success
end

function util.tryWaitNetwork(timeout)
  local tryNum = timeout or 30
  local gw, success = util.shell("ip r | grep default | cut -d ' ' -f 3 | head -n 1")
  if success then
    print("GW " .. gw)
    while (tryNum > 0) do
      if util.destIsReachable(gw) then return true end
      print("retry times: " .. tostring(tryNum))
      tryNum = tryNum - 1
    end
    print("Networking check ok ...")
  end
  return false
end

function util.destIsReachable(dest)
  local cmd
  if (IsDarwin()) then
    cmd = "ping -q -t 5 -c 1 " .. dest
  else
    cmd = "ping -q -w 5 -c 1 " .. dest
  end
  return os.execute(cmd)
end

function util.patchGit()
  print("check git safe.directory setup");
  if os.execute("git config --get safe.directory |grep `pwd`") then return end
  print("apply git safe.directory for system");
  if not os.execute("git config --system --add safe.directory `pwd`") then print("fail to apply git patch") end
end

function util.gitSetup()
  local cmds = {
    "git config user.email 'hummingbirdiot@example.com'",
    "git config user.name 'hummingbirdiot'"
  }
  return util.runAllcmd(cmds)
end

function util.sleep(n)
  os.execute("sleep " .. tonumber(n))
end

function util.upstreamUpdate(useSudo)
  local branch, success = util.shell("git rev-parse --abbrev-ref HEAD")
  if not success then
    return false
  end
  if useSudo then print("No need sudo for openwrt") end
  local cmd = "git fetch origin " .. branch
  print("cmd is " .. cmd)
  if os.execute(cmd) then
    local headHash, success_1 = util.shell("git rev-parse HEAD")
    if not success_1 then
      return false
    end
    headHash = util.trim(headHash)
    local upstreamHash, success_2 = util.shell("git rev-parse @{upstream}")
    if not success_2 then
      return false
    end
    upstreamHash = util.trim(upstreamHash)
    print(headHash .. " " .. upstreamHash)
    return headHash ~= upstreamHash
  end
end

local launch_cmd = "lua5.3 ./init.lua"
function util.syncToUpstream(useSudo, cleanFunc)
  if util.upstreamUpdate(useSudo) and not file.exists(OTA_STATUS_FILE) then
    print("Do self update")
    file.write(OTA_STATUS_FILE, os.date(), "w")
    cleanFunc()
    util.runAllcmd({
        "git stash",
        "git merge '@{u}'"
      })
    file.remove(OTA_STATUS_FILE)
    if not os.execute(launch_cmd) then print("Fail to start hiot") end
    os.exit(0)
  end
  return true
end

return util
