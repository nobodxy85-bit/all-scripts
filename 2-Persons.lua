-- VISUAL PLAYER CLONE WITH DELAY
-- Creator: Nobodxy85-bit (adapted)
-- Delay: 0.5 seconds

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LOCAL_PLAYER = Players.LocalPlayer

-- ===== CONFIG =====
local TARGET_USER_ID = 3180109012
local DELAY_SECONDS = 0.3

-- ===== VARIABLES =====
local targetPlayer
local cloneCharacter
local positionBuffer = {}

-- ===== CREATE VISUAL CLONE =====
local function createClone(description)
    cloneCharacter = Instance.new("Model")
    cloneCharacter.Name = "VisualClone"

    local humanoid = Instance.new("Humanoid")
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    humanoid.Parent = cloneCharacter

    humanoid:ApplyDescription(description)

    cloneCharacter.Parent = workspace
    cloneCharacter:SetPrimaryPartCFrame(CFrame.new(0, -1000, 0))

    -- no collision
    for _, v in ipairs(cloneCharacter:GetDescendants()) do
        if v:IsA("BasePart") then
            v.CanCollide = false
            v.Anchored = false
        end
    end
end

-- ===== BUFFER HANDLING =====
local function recordPosition(cf)
    table.insert(positionBuffer, {
        time = tick(),
        cframe = cf
    })
end

local function getDelayedCFrame()
    local now = tick()
    for i, data in ipairs(positionBuffer) do
        if now - data.time >= DELAY_SECONDS then
            table.remove(positionBuffer, i)
            return data.cframe
        end
    end
end

-- ===== FIND PLAYER BY USERID =====
local function findTarget()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.UserId == TARGET_USER_ID then
            return plr
        end
    end
end

-- ===== MAIN =====
task.spawn(function()
    repeat task.wait(1) until findTarget()
    targetPlayer = findTarget()

    repeat task.wait() until targetPlayer.Character
    local char = targetPlayer.Character
    local humanoid = char:WaitForChild("Humanoid")

    local description = humanoid:GetAppliedDescription()
    createClone(description)

    RunService.Heartbeat:Connect(function()
        if not char.PrimaryPart or not cloneCharacter.PrimaryPart then return end

        recordPosition(char.PrimaryPart.CFrame)

        local delayedCF = getDelayedCFrame()
        if delayedCF then
            cloneCharacter:SetPrimaryPartCFrame(delayedCF)
        end
    end)
end)
