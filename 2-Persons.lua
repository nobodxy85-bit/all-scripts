-- VISUAL CLONE QUE COPIA ANIMACIONES + TOGGLE Z
-- Sigue al jugador / se congela en su posición
-- Creator = Nobodxy85-bit

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local OFFSET = CFrame.new(-5, 0, 0) -- izquierda

-- Estado
local following = true
local frozenOffset = nil

-- Esperar personaje
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")

-- Crear clon
local clone = Players:CreateHumanoidModelFromUserId(player.UserId)
clone.Name = "VisualClone"
clone.Parent = workspace

local cloneHumanoid = clone:WaitForChild("Humanoid")
local cloneHRP = clone:WaitForChild("HumanoidRootPart")
clone.PrimaryPart = cloneHRP

cloneHumanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

-- Ajustes visuales
for _, v in ipairs(clone:GetDescendants()) do
	if v:IsA("BasePart") then
		v.Anchored = true
		v.CanCollide = false
		v.Transparency = 0.1 -- fantasma
	end
end

-- ===== COPIAR ANIMACIONES =====
local cloneAnimator = cloneHumanoid:WaitForChild("Animator")

humanoid.AnimationPlayed:Connect(function(track)
	local anim = Instance.new("Animation")
	anim.AnimationId = track.Animation.AnimationId

	local newTrack = cloneAnimator:LoadAnimation(anim)
	newTrack.Priority = track.Priority
	newTrack:Play()

	-- sincronizar velocidad
	RunService.RenderStepped:Connect(function()
		if newTrack.IsPlaying then
			newTrack:AdjustSpeed(track.Speed)
		end
	end)
end)

-- ===== TECLA Z (FREEZE / FOLLOW) =====
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.Z then
		following = not following

		if not following then
			-- guardar offset actual
			frozenOffset = hrp.CFrame:ToObjectSpace(cloneHRP.CFrame)
		else
			-- reanudar desde donde quedó
			frozenOffset = frozenOffset or OFFSET
		end
	end
end)

-- ===== LOOP PRINCIPAL =====
RunService.RenderStepped:Connect(function()
	if not clone or not clone.PrimaryPart then return end

	if following then
		local offset = frozenOffset or OFFSET
		clone:SetPrimaryPartCFrame(hrp.CFrame * offset)
	end
end)
