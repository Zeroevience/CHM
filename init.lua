local M = {}

local lpm = loadstring(readfile("lpm/init.lua"))()
local client = lpm("require", "Zeroevience/ClientInfo")

local flying = false
local flyConn = nil
local bodyVel = nil

function M.speed(speed)
    client.Character.Humanoid.WalkSpeed = speed
    return "Done"
end

function M.fly(method)
    if flying then return "Already flying" end

    local char = client.Character
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")

    if not root or not humanoid then
        return "Character not ready"
    end

    flying = true

    if method == "bypass" then
        bodyVel = Instance.new("BodyVelocity")
        bodyVel.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        bodyVel.Velocity = Vector3.new(0, 0, 0)
        bodyVel.Parent = root

        flyConn = game:GetService("RunService").Heartbeat:Connect(function()
            if not flying then return end

            local cam = workspace.CurrentCamera
            local move = humanoid.MoveDirection

            bodyVel.Velocity =
                (cam.CFrame.LookVector * move.Z +
                 cam.CFrame.RightVector * move.X) * 60
        end)

    else
        bodyVel = Instance.new("BodyVelocity")
        bodyVel.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        bodyVel.Velocity = Vector3.new(0, 50, 0)
        bodyVel.Parent = root
    end

    return "Flying"
end

function M.unfly()
    if not flying then return "Not flying" end

    flying = false

    if flyConn then
        flyConn:Disconnect()
        flyConn = nil
    end

    if bodyVel then
        bodyVel:Destroy()
        bodyVel = nil
    end

    return "Stopped flying"
end

return M
