-- VISUAL CLONE ESTABLE + ANIMACIONES + TOGGLE Z
-- Sin teleports raros, con suavizado real

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local OFFSET = CFrame.new(-5, 0, 0)
local SMOOTHNESS = 0.15 -- menor = más suave

-- Estado
local following = true
local frozenCFrame = nil
local currentCFrame = nil

-- Esperar character
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

-- Visual
for _, v in ipairs(clone:GetDescendants()) do
	if v:IsA("BasePart") then
		v.Anchored = true
		v.CanCollide = false
		v.Transparency = 0.2
	end
end

-- ===== COPIA DE ANIMATOR (CLAVE) =====
local function syncAnimator()
	local srcAnimator = humanoid:WaitForChild("Animator")
	local dstAnimator = cloneHumanoid:WaitForChild("Animator")

	RunService.RenderStepped:Connect(function()
		for _, track in ipairs(srcAnimator:GetPlayingAnimationTracks()) do
			local found = false
			for _, cTrack in ipairs(dstAnimator:GetPlayingAnimationTracks()) do
				if cTrack.Animation.AnimationId == track.Animation.AnimationId then
					cTrack.TimePosition = track.TimePosition
					cTrack:AdjustSpeed(track.Speed)
					found = true
					break
				end
			end
			if not found then
				local anim = Instance.new("Animation")
				anim.AnimationId = track.Animation.AnimationId
				local newTrack = dstAnimator:LoadAnimation(anim)
				newTrack.Priority = track.Priority
				newTrack:Play(0)
			end
		end
	end)
end

syncAnimator()

-- ===== TECLA Z =====
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.Z then
		following = not following
		if not following then
			frozenCFrame = currentCFrame
		end
	end
end)

-- ===== LOOP SUAVIZADO =====
RunService.RenderStepped:Connect(function()
	if not clone.PrimaryPart then return end

	if following then
		local target = hrp.CFrame * OFFSET
		currentCFrame = currentCFrame and currentCFrame:Lerp(target, SMOOTHNESS) or target
	else
		currentCFrame = frozenCFrame
	end

	if currentCFrame then
		clone:SetPrimaryPartCFrame(currentCFrame)
	end
end)
