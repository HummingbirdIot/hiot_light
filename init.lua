local PWD = os.getenv("PWD")
if PWD then
  package.path = PWD .. "/lua/?.lua;" .. package.path
end

local hiot = require('hummingbird_iot')
hiot.Run();
