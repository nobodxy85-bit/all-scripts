-- VISUAL CLONE CON ANIMACIONES + TOGGLE Z + SIN COLISIONES
-- Sigue al jugador suavemente y puede congelarse en el lugar
-- Creator = Nobodxy85-bit

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local PhysicsService = game:GetService("PhysicsService")

local player = Players.LocalPlayer
local OFFSET = CFrame.new(-5, 0, 0)
local SMOOTHNESS = 0.15

-- ===== COLLISION GROUPS =====
local CLONE_GROUP = "VisualClone"
local PLAYER_GROUP = "LocalPlayer"

pcall(function() PhysicsService:CreateCollisionGroup(CLONE_GROUP) end)
pcall(function() PhysicsService:CreateCollisionGroup(PLAYER_GROUP) end)

PhysicsService:CollisionGroupSetCollidable(CLONE_GROUP, PLAYER_GROUP, false)
PhysicsService:CollisionGroupSetCollidable(CLONE_GROUP, CLONE_GROUP, false)

-- ===== ESTADO =====
local following = true
local frozenPosition = nil
local lastPlayerCFrame = nil
local currentCFrame = nil

-- ===== PERSONAJE =====
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")

-- Asignar collision group al jugador
for _, v in ipairs(character:GetDescendants()) do
	if v:IsA("BasePart") then
		PhysicsService:SetPartCollisionGroup(v, PLAYER_GROUP)
	end
end

-- ===== CREAR CLON =====
local clone = Players:CreateHumanoidModelFromUserId(player.UserId)
clone.Name = "VisualClone"
clone.Parent = workspace

local cloneHumanoid = clone:WaitForChild("Humanoid")
local cloneHRP = clone:WaitForChild("HumanoidRootPart")
clone.PrimaryPart = cloneHRP

cloneHumanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

-- Ajustes visuales y colisiones
for _, v in ipairs(clone:GetDescendants()) do
	if v:IsA("BasePart") then
		v.CanCollide = false
		v.Transparency = 0.2
		PhysicsService:SetPartCollisionGroup(v, CLONE_GROUP)

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
		for _, d in ipairs(dstTracks) do
			local keep = false
			for _, s in ipairs(srcTracks) do
				if d.Animation.AnimationId == s.Animation.AnimationId then
					keep = true
					break
				end
			end
			if not keep then
				d:Stop()
			end
		end

		-- sincronizar activas
		for _, s in ipairs(srcTracks) do
			local found = false
			for _, d in ipairs(dstTracks) do
				if d.Animation.AnimationId == s.Animation.AnimationId then
					d.TimePosition = s.TimePosition
					d:AdjustSpeed(s.Speed)
					found = true
					break
				end
			end

			if not found then
				local anim = Instance.new("Animation")
				anim.AnimationId = s.Animation.AnimationId
				local nt = dstAnimator:LoadAnimation(anim)
				nt.Priority = s.Priority
				nt:Play(0, 1, s.Speed)
				nt.TimePosition = s.TimePosition
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

-- ===== MOVIMIENTO SUAVIZADO =====
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
