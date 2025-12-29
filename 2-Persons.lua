-- VISUAL PLAYER CLONE WITH REAL DELAY (WORKING)
-- Creator: Nobodxy85-bit
-- FIXED VERSION

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- ===== CONFIG =====
local TARGET_USER_ID = 3180109012 -- CAMBIA ESTO
local DELAY = 0.5

-- ===== VARIABLES =====
local targetPlayer
local clone
local buffer = {}

-- ===== CREATE CLONE =====
local function createCloneFromUserId(userId)
    local model = Players:CreateHumanoidModelFromUserId(userId)
    model.Name = "VisualClone"

    model.Parent = workspace

    local hrp = model:WaitForChild("HumanoidRootPart")
    model.PrimaryPart = hrp

    for _, v in ipairs(model:GetDescendants()) do
        if v:IsA("BasePart") then
            v.CanCollide = false
            v.Anchored = true
        end
    end

    return model
end

-- ===== BUFFER =====
local function push(cf)
    table.insert(buffer, {
        t = time(),
        cf = cf
    })
end

local function pop()
    local now = time()
    for i, data in ipairs(buffer) do
        if now - data.t >= DELAY then
            table.remove(buffer, i)
            return data.cf
        end
    end
end

-- ===== FIND PLAYER =====
local function getTarget()
    for _, p in ipairs(Players:GetPlayers()) do
        if p.UserId == TARGET_USER_ID then
            return p
        end
    end
end

-- ===== MAIN =====
task.spawn(function()
    repeat task.wait(1) until getTarget()
    targetPlayer = getTarget()

    repeat task.wait() until targetPlayer.Character
    local char = targetPlayer.Character
    local hrp = char:WaitForChild("HumanoidRootPart")

    clone = createCloneFromUserId(TARGET_USER_ID)

    RunService.RenderStepped:Connect(function()
        if not hrp or not clone or not clone.PrimaryPart then return end

        push(hrp.CFrame)

        local delayed = pop()
        if delayed then
            clone:SetPrimaryPartCFrame(delayed)
        end
    end)
end)
