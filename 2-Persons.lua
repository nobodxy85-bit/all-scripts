-- LOCAL PLAYER VISUAL CLONE (MIRROR)
-- Copia tus movimientos y aparece a tu izquierda
-- Creator = Nobodxy85-bit :D

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local OFFSET = CFrame.new(-3, 0, 0) -- izquierda (X negativo)

-- Esperar personaje
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

-- Crear clon visual usando tu avatar
local clone = Players:CreateHumanoidModelFromUserId(player.UserId)
clone.Name = "VisualClone"
clone.Parent = workspace

-- PrimaryPart
local cloneRoot = clone:WaitForChild("HumanoidRootPart")
clone.PrimaryPart = cloneRoot

-- Ajustes visuales
for _, v in ipairs(clone:GetDescendants()) do
	if v:IsA("BasePart") then
		v.Anchored = true
		v.CanCollide = false
        v.Transparency = 0.5
	end
end

-- Quitar nombre
clone:FindFirstChildOfClass("Humanoid").DisplayDistanceType =
	Enum.HumanoidDisplayDistanceType.None

-- Copiar animaciones
local cloneHumanoid = clone:FindFirstChildOfClass("Humanoid")
local animator = cloneHumanoid:WaitForChild("Animator")

humanoid.AnimationPlayed:Connect(function(track)
	local anim = Instance.new("Animation")
	anim.AnimationId = track.Animation.AnimationId
	local newTrack = animator:LoadAnimation(anim)
	newTrack:Play()
end)

-- Sincronizar posición y rotación
RunService.RenderStepped:Connect(function()
	if hrp and clone.PrimaryPart then
		clone:SetPrimaryPartCFrame(hrp.CFrame * OFFSET)
	end
end)
