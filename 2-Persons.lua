-- VISUAL PLAYER CLONE (APPEARANCE ONLY)
-- Funciona aunque el jugador NO esté en el server
-- Creador = Nobodxy85-bit

local Players = game:GetService("Players")

-- ===== CONFIG =====
local TARGET_USER_ID = 3180109012 -- << CAMBIA ESTE ID

-- ===== CREATE VISUAL CLONE =====
local function createVisualClone(userId)
    local model = Players:CreateHumanoidModelFromUserId(userId)
    model.Name = "VisualClone_" .. userId
    model.Parent = workspace

    -- Asegurar PrimaryPart
    local hrp = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart")
    if hrp then
        model.PrimaryPart = hrp
        model:SetPrimaryPartCFrame(CFrame.new(0, 5, 0)) -- posición inicial
    end

    -- Ajustes visuales
    for _, v in ipairs(model:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Anchored = true
            v.CanCollide = false
        end
    end

    return model
end

-- ===== RUN =====
createVisualClone(TARGET_USER_ID)
