local M = {}

local lpm = loadstring(readfile("lpm/init.lua"))()
lpm("update", "Zeroevience/ClientInfo")

local client = lpm("require", "Zeroevience/ClientInfo")

local flying = false
local flyConn = nil
local bodyVel = nil

local noclip = false
local noclipConn = nil

local broken = false
local nofallEnabled = false
local animPlaying = false

local savedJoints = {}
local Parts = {}

local RunService = game:GetService("RunService")

function M.speed(speed)
    if client.Character and client.Character:FindFirstChildOfClass("Humanoid") then
        client.Character.Humanoid.WalkSpeed = speed
        return "Done"
    end
    return "Character not ready"
end

function M.fly(method, speed)
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

    local flySpeed = tonumber(speed) or ((method == "bypass") and 90 or 60)

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

        bodyVel.Velocity = direction * flySpeed
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

function M.breakjoints(nofall)
    local char = client.Character
    if not char then return "Character not ready" end

    local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
    if not torso then return "No torso" end

    nofallEnabled = nofall or false

    local joints = {
        "Right Shoulder", "Left Shoulder",
        "Right Hip", "Left Hip"
    }

    for _, name in ipairs(joints) do
        local joint = torso:FindFirstChild(name)
        if joint and joint:IsA("Motor6D") then
            savedJoints[name] = {
                C0 = joint.C0,
                C1 = joint.C1,
                Part = joint.Part1
            }
            joint:Destroy()
        end
    end

    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") then
            v.CanCollide = false
            v.Massless = true
            Parts[v.Name] = v
        end
    end

    broken = true

    if nofallEnabled then
        RunService.Heartbeat:Connect(function()
            if not broken or animPlaying then return end

            local torso = Parts["Torso"] or Parts["UpperTorso"]
            if not torso then return end

            for _, data in pairs(savedJoints) do
                local part = data.Part
                if part then
                    local target = torso.CFrame * data.C0 * data.C1:Inverse()
                    part.CFrame = part.CFrame:Lerp(target, 0.3)

                    part.Velocity = Vector3.zero
                    part.RotVelocity = Vector3.zero
                end
            end
        end)
    end

    return "Joints broken"
end

function M.playanimation(data)
    if not broken then
        return "Break joints first"
    end

    animPlaying = true

    local torso = Parts["Torso"] or Parts["UpperTorso"]
    if not torso then return "No torso" end

    local currentKeyframe = 1
    local t = 0

    local conn
    conn = RunService.Heartbeat:Connect(function(dt)
        if currentKeyframe >= #data.Keyframes then
            animPlaying = false
            conn:Disconnect()
            return
        end

        local kf1 = data.Keyframes[currentKeyframe]
        local kf2 = data.Keyframes[currentKeyframe + 1]

        local duration = kf2.Time - kf1.Time
        t += dt

        local alpha = math.clamp(t / duration, 0, 1)

        for partName, cf1 in pairs(kf1.Poses) do
            local cf2 = kf2.Poses[partName]

            for _, jointData in pairs(savedJoints) do
                local part = jointData.Part

                if part and part.Name == partName and cf2 then
                    local animCF = cf1:Lerp(cf2, alpha)
                    local final = torso.CFrame * jointData.C0 * animCF * jointData.C1:Inverse()

                    part.CFrame = part.CFrame:Lerp(final, 0.4)

                    part.Velocity = Vector3.zero
                    part.RotVelocity = Vector3.zero
                end
            end
        end

        if t >= duration then
            t = 0
            currentKeyframe += 1
        end
    end)

    return "Playing animation"
end

return M
