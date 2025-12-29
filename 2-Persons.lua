-- VISUAL CLONE CON ANIMACIONES + TOGGLE Z (SE QUEDA EN LUGAR PERO TE COPIA)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local OFFSET = CFrame.new(-5, 0, 0)
local SMOOTHNESS = 0.15

-- Estado
local following = true
local frozenPosition = nil
local lastPlayerCFrame = nil

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

-- Visual - SOLO anclar HumanoidRootPart
for _, v in ipairs(clone:GetDescendants()) do
	if v:IsA("BasePart") then
		v.CanCollide = false
		v.Transparency = 0.2
		if v == cloneHRP then
			v.Anchored = true
		else
			v.Anchored = false
		end
	end
end

-- Copiar accesorios del jugador
for _, obj in ipairs(character:GetChildren()) do
	if obj:IsA("Accessory") then
		local cloneAccessory = obj:Clone()
		cloneAccessory.Parent = clone
	end
end

-- ===== SINCRONIZAR ANIMACIONES =====
local function syncAnimator()
	local srcAnimator = humanoid:FindFirstChildOfClass("Animator")
	local dstAnimator = cloneHumanoid:FindFirstChildOfClass("Animator")
	
	if not srcAnimator or not dstAnimator then
		return
	end
	
	RunService.RenderStepped:Connect(function()
		local srcTracks = srcAnimator:GetPlayingAnimationTracks()
		local dstTracks = dstAnimator:GetPlayingAnimationTracks()
		
		-- Detener animaciones que ya no están en el original
		for _, dstTrack in ipairs(dstTracks) do
			local found = false
			for _, srcTrack in ipairs(srcTracks) do
				if dstTrack.Animation.AnimationId == srcTrack.Animation.AnimationId then
					found = true
					break
				end
			end
			if not found then
				dstTrack:Stop()
			end
		end
		
		-- Sincronizar animaciones activas
		for _, srcTrack in ipairs(srcTracks) do
			local found = false
			for _, dstTrack in ipairs(dstTracks) do
				if dstTrack.Animation.AnimationId == srcTrack.Animation.AnimationId then
					dstTrack.TimePosition = srcTrack.TimePosition
					dstTrack:AdjustSpeed(srcTrack.Speed)
					found = true
					break
				end
			end
			
			if not found then
				local anim = Instance.new("Animation")
				anim.AnimationId = srcTrack.Animation.AnimationId
				local newTrack = dstAnimator:LoadAnimation(anim)
				newTrack.Priority = srcTrack.Priority
				newTrack:Play(0, 1, srcTrack.Speed)
				newTrack.TimePosition = srcTrack.TimePosition
			end
		end
	end)
end

task.wait(0.1)
syncAnimator()

-- ===== TOGGLE CON Z =====
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.Z then
		following = not following
		if not following then
			frozenPosition = cloneHRP.Position
			lastPlayerCFrame = hrp.CFrame
		else
			frozenPosition = nil
			lastPlayerCFrame = nil
		end
	end
end)

-- ===== MOVIMIENTO =====
local currentCFrame = nil

RunService.RenderStepped:Connect(function()
	if not clone.PrimaryPart then return end
	
	local targetCFrame
	
	if following then
		targetCFrame = hrp.CFrame * OFFSET
	else
		if frozenPosition and lastPlayerCFrame then
			local playerMovement = lastPlayerCFrame:Inverse() * hrp.CFrame
			local frozenCFrame = CFrame.new(frozenPosition) * (playerMovement - playerMovement.Position)
			targetCFrame = frozenCFrame
			lastPlayerCFrame = hrp.CFrame
		else
			targetCFrame = cloneHRP.CFrame
		end
	end
	
	currentCFrame = currentCFrame and currentCFrame:Lerp(targetCFrame, SMOOTHNESS) or targetCFrame
	cloneHRP.CFrame = currentCFrame
end)
