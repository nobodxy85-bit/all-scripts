-- VISUAL CLONE CON ANIMACIONES + TOGGLE Z (NO COLISIONA)
-- Creator = Nobodxy85-bit

-- ===== SERVICIOS =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local PhysicsService = game:GetService("PhysicsService")

local player = Players.LocalPlayer
local OFFSET = CFrame.new(-5, 0, 0)
local SMOOTHNESS = 0.15

-- ===== COLLISION GROUP =====
pcall(function()
	PhysicsService:CreateCollisionGroup("VisualClone")
end)

PhysicsService:CollisionGroupSetCollidable("VisualClone", "Default", false)

-- ===== ESTADO =====
local following = true
local frozenPosition = nil
local lastPlayerCFrame = nil
local currentCFrame = nil

-- ===== ESPERAR CHARACTER =====
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")

-- ===== CREAR CLON =====
local clone = Players:CreateHumanoidModelFromUserId(player.UserId)
clone.Name = "VisualClone"
clone.Parent = workspace

local cloneHumanoid = clone:WaitForChild("Humanoid")
local cloneHRP = clone:WaitForChild("HumanoidRootPart")
clone.PrimaryPart = cloneHRP

cloneHumanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

-- ===== CONFIG VISUAL + COLISION =====
for _, v in ipairs(clone:GetDescendants()) do
	if v:IsA("BasePart") then
		v.CanCollide = false
		v.CanTouch = false
		v.CanQuery = false
		v.Transparency = 0.2
		
		-- 🔒 NO COLISIONA CON NADIE
		PhysicsService:SetPartCollisionGroup(v, "VisualClone")

		if v == cloneHRP then
			v.Anchored = true
		else
			v.Anchored = false
		end
	end
end

-- ===== COPIAR ACCESORIOS =====
for _, obj in ipairs(character:GetChildren()) do
	if obj:IsA("Accessory") then
		obj:Clone().Parent = clone
	end
end

-- ===== SINCRONIZAR ANIMACIONES =====
local function syncAnimator()
	local srcAnimator = humanoid:FindFirstChildOfClass("Animator")
	local dstAnimator = cloneHumanoid:FindFirstChildOfClass("Animator")
	if not srcAnimator or not dstAnimator then return end

	RunService.RenderStepped:Connect(function()
		local srcTracks = srcAnimator:GetPlayingAnimationTracks()
		local dstTracks = dstAnimator:GetPlayingAnimationTracks()

		-- detener animaciones sobrantes
		for _, dst in ipairs(dstTracks) do
			local found = false
			for _, src in ipairs(srcTracks) do
				if dst.Animation.AnimationId == src.Animation.AnimationId then
					found = true
					break
				end
			end
			if not found then
				dst:Stop()
			end
		end

		-- copiar animaciones
		for _, src in ipairs(srcTracks) do
			local found = false
			for _, dst in ipairs(dstTracks) do
				if dst.Animation.AnimationId == src.Animation.AnimationId then
					dst.TimePosition = src.TimePosition
					dst:AdjustSpeed(src.Speed)
					found = true
					break
				end
			end

			if not found then
				local anim = Instance.new("Animation")
				anim.AnimationId = src.Animation.AnimationId
				local track = dstAnimator:LoadAnimation(anim)
				track.Priority = src.Priority
				track:Play(0, 1, src.Speed)
				track.TimePosition = src.TimePosition
			end
		end
	end)
end

task.wait(0.1)
syncAnimator()

-- ===== TOGGLE Z =====
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
RunService.RenderStepped:Connect(function()
	if not clone.PrimaryPart then return end

	local targetCFrame

	if following then
		targetCFrame = hrp.CFrame * OFFSET
	else
		if frozenPosition and lastPlayerCFrame then
			local delta = lastPlayerCFrame:Inverse() * hrp.CFrame
			targetCFrame = CFrame.new(frozenPosition) * (delta - delta.Position)
			lastPlayerCFrame = hrp.CFrame
		else
			targetCFrame = cloneHRP.CFrame
		end
	end

	currentCFrame = currentCFrame and currentCFrame:Lerp(targetCFrame, SMOOTHNESS) or targetCFrame
	cloneHRP.CFrame = currentCFrame
end)
