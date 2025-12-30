-- VISUAL CLONE CON ANIMACIONES + TOGGLE Z (SE QUEDA EN LUGAR PERO TE COPIA)
-- + TELETRANSPORTE CON X (cuando está congelado)
-- Creator = Nobodxy85-bit
-- Modified: Added teleport feature

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local PhysicsService = game:GetService("PhysicsService")

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

-- Crear grupo de colisión
pcall(function()
	PhysicsService:RegisterCollisionGroup("CloneGroup")
	PhysicsService:CollisionGroupSetCollidable("CloneGroup", "CloneGroup", false)
	PhysicsService:CollisionGroupSetCollidable("CloneGroup", "Default", false)
end)

-- Crear clon
local clone = Players:CreateHumanoidModelFromUserId(player.UserId)
clone.Name = "VisualClone"
clone.Parent = workspace
local cloneHumanoid = clone:WaitForChild("Humanoid")
local cloneHRP = clone:WaitForChild("HumanoidRootPart")
clone.PrimaryPart = cloneHRP
cloneHumanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

-- Visual - SIN ANCLAR, usar AlignPosition en su lugar
for _, v in ipairs(clone:GetDescendants()) do
	if v:IsA("BasePart") then
		v.CanCollide = false
		v.Transparency = 0.2
		v.Massless = true
		v.Anchored = false -- TODAS las partes desancladas
		
		-- Aplicar grupo de colisión
		pcall(function()
			PhysicsService:SetPartCollisionGroup(v, "CloneGroup")
		end)
	end
end

-- Crear AttachmentAlign para controlar posición sin anclar
local attachment0 = Instance.new("Attachment")
attachment0.Parent = cloneHRP

local attachment1 = Instance.new("Attachment")
attachment1.Parent = workspace.Terrain

local alignPosition = Instance.new("AlignPosition")
alignPosition.Attachment0 = attachment0
alignPosition.Attachment1 = attachment1
alignPosition.MaxForce = math.huge
alignPosition.MaxVelocity = math.huge
alignPosition.Responsiveness = 200
alignPosition.ApplyAtCenterOfMass = true
alignPosition.Parent = cloneHRP

local alignOrientation = Instance.new("AlignOrientation")
alignOrientation.Attachment0 = attachment0
alignOrientation.Attachment1 = attachment1
alignOrientation.MaxTorque = math.huge
alignOrientation.MaxAngularVelocity = math.huge
alignOrientation.Responsiveness = 200
alignOrientation.Parent = cloneHRP

-- Copiar accesorios del jugador
for _, obj in ipairs(character:GetChildren()) do
	if obj:IsA("Accessory") then
		local cloneAccessory = obj:Clone()
		cloneAccessory.Parent = clone
		
		-- Sin colisiones para accesorios
		for _, part in ipairs(cloneAccessory:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
				part.Massless = true
				pcall(function()
					PhysicsService:SetPartCollisionGroup(part, "CloneGroup")
				end)
			end
		end
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

-- ===== FUNCIÓN DE TELETRANSPORTE =====
local function teleportToClone()
	if not following and cloneHRP then
		-- Teletransportar el jugador a la posición del clon
		hrp.CFrame = cloneHRP.CFrame
		
		-- Opcional: Efecto visual de teletransporte
		local teleportEffect = Instance.new("Part")
		teleportEffect.Size = Vector3.new(5, 5, 5)
		teleportEffect.Transparency = 0.5
		teleportEffect.Color = Color3.fromRGB(0, 170, 255)
		teleportEffect.Material = Enum.Material.Neon
		teleportEffect.Anchored = true
		teleportEffect.CanCollide = false
		teleportEffect.CFrame = hrp.CFrame
		teleportEffect.Parent = workspace
		
		-- Animar el efecto
		task.spawn(function()
			for i = 1, 10 do
				teleportEffect.Transparency = teleportEffect.Transparency + 0.05
				teleportEffect.Size = teleportEffect.Size + Vector3.new(0.5, 0.5, 0.5)
				task.wait(0.03)
			end
			teleportEffect:Destroy()
		end)
	end
end

-- ===== CONTROLES DE TECLADO =====
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	
	-- Toggle congelar/seguir con Z
	if input.KeyCode == Enum.KeyCode.Z then
		following = not following
		if not following then
			frozenPosition = cloneHRP.Position
			lastPlayerCFrame = hrp.CFrame
			print("Clon CONGELADO - Presiona X para teletransportarte")
		else
			frozenPosition = nil
			lastPlayerCFrame = nil
			print("Clon SIGUIENDO")
		end
	end
	
	-- Teletransporte con X (solo cuando está congelado)
	if input.KeyCode == Enum.KeyCode.X then
		if not following then
			teleportToClone()
			print("¡Teletransportado al clon!")
		else
			print("El clon debe estar CONGELADO (presiona Z primero)")
		end
	end
end)

-- ===== MOVIMIENTO =====
local currentCFrame = nil
RunService.RenderStepped:Connect(function()
	if not clone.PrimaryPart or not attachment1 then return end
	
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
	
	-- Actualizar los attachments para controlar posición
	attachment1.WorldCFrame = currentCFrame
end)

-- Mensaje inicial
print("=================================")
print("CONTROLES:")
print("Z - Congelar/Descongelar clon")
print("X - Teletransportarse al clon (cuando está congelado)")
print("=================================")
