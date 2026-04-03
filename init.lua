
local M = {}
local lpm = loadstring(readfile("lpm/init.lua"))()
lpm("install", "Zeroevience/ClientInfo")
local client = lpm("require", "Zeroevience/ClientInfo")
function M.speed(speed)
    client.Character.Humanoid.WalkSpeed = speed
    return "Done"
end

return M
