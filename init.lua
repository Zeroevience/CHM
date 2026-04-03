
local M = {}
local lpm = loadstring(readfile("lpm/init.lua"))()
lpm("install", "Zeroevience/ClientInfo")
local client = lpm("require", "Zeroevience/ClientInfo")
function M.speed(...)
    local args=...
    client.Character.Humanoid.Walkspeed = args[1]
    return "Done"
end

return M
