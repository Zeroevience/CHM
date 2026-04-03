local M = {}

local lpm = loadstring(readfile("lpm/init.lua"))()
lpm("update", "Zeroevience/ClientInfo")

local client = lpm("require", "Zeroevience/ClientInfo")

local flying = false
local flyConn = nil
local bodyVel = nil

local noclip = false
local noclipConn = nil

function M.speed(speed)
    if client.Character and client.Character:FindFirstChildOfClass("Humanoid") then
        client.Character.Humanoid.WalkSpeed = speed
        return "Done"
    end
    return "Character not ready"
end

function M.fly(method)
    if flying then return "Already flying" end

    local char = client.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")

    if not root or not humanoid then
        return "Character not ready"
    end

    flying = true

    bodyVel = Instance.new("BodyVelocity")
    bodyVel.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    bodyVel.Velocity = Vector3.zero
    bodyVel.Parent = root

    local UIS = game:GetService("UserInputService")
    local RS = game:GetService("RunService")

    flyConn = RS.Heartbeat:Connect(function()
        if not flying then return end

        local cam = workspace.CurrentCamera
        local direction = Vector3.zero

        if UIS:IsKeyDown(Enum.KeyCode.W) then
            direction += cam.CFrame.LookVector
        end
        if UIS:IsKeyDown(Enum.KeyCode.S) then
            direction -= cam.CFrame.LookVector
        end
        if UIS:IsKeyDown(Enum.KeyCode.A) then
            direction -= cam.CFrame.RightVector
        end
        if UIS:IsKeyDown(Enum.KeyCode.D) then
            direction += cam.CFrame.RightVector
        end

        local y = 0
        if UIS:IsKeyDown(Enum.KeyCode.E) then
            y = 1
        elseif UIS:IsKeyDown(Enum.KeyCode.Q) then
            y = -1
        end

        direction += Vector3.new(0, y, 0)

        if direction.Magnitude > 0 then
            direction = direction.Unit
        end

        local speed = (method == "bypass") and 90 or 60
        bodyVel.Velocity = direction * speed
    end)

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

function M.noclip()
    if noclip then return "Already noclipping" end

    noclip = true

    noclipConn = game:GetService("RunService").Stepped:Connect(function()
        if not noclip then return end

        local char = client.Character
        if not char then return end

        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)

    return "Noclip enabled"
end

function M.clip()
    if not noclip then return "Not noclipping" end

    noclip = false

    if noclipConn then
        noclipConn:Disconnect()
        noclipConn = nil
    end

    local char = client.Character
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end

    return "Noclip disabled"
end

return M
