-- VISUAL CLONE CON ANIMACIONES + TOGGLE Z + GUI TOGGLE X D:
-- Creator = Nobodxy85-bit
-- Enhanced by Claude

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
local clone = nil
local cloneHumanoid = nil
local cloneHRP = nil

-- Esperar character
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")

-- ===== CREAR GUI =====
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CloneConfigGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 300, 0, 150)
mainFrame.Position = UDim2.new(0.5, -150, 0.5, -75)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
mainFrame.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 8)
uiCorner.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, 0, 0, 40)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
titleLabel.BorderSizePixel = 0
titleLabel.Text = "VISUAL CLONE CONFIG"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 16
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = titleLabel

local inputLabel = Instance.new("TextLabel")
inputLabel.Name = "InputLabel"
inputLabel.Size = UDim2.new(0, 280, 0, 20)
inputLabel.Position = UDim2.new(0, 10, 0, 50)
inputLabel.BackgroundTransparency = 1
inputLabel.Text = "User ID del jugador:"
inputLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
inputLabel.TextSize = 14
inputLabel.Font = Enum.Font.Gotham
inputLabel.TextXAlignment = Enum.TextXAlignment.Left
inputLabel.Parent = mainFrame

local textBox = Instance.new("TextBox")
textBox.Name = "UserIdInput"
textBox.Size = UDim2.new(0, 280, 0, 35)
textBox.Position = UDim2.new(0, 10, 0, 75)
textBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
textBox.BorderSizePixel = 1
textBox.BorderColor3 = Color3.fromRGB(100, 100, 100)
textBox.Text = tostring(player.UserId)
textBox.PlaceholderText = "Ingresa User ID..."
textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
textBox.TextSize = 14
textBox.Font = Enum.Font.Gotham
textBox.ClearTextOnFocus = false
textBox.Parent = mainFrame

local textBoxCorner = Instance.new("UICorner")
textBoxCorner.CornerRadius = UDim.new(0, 4)
textBoxCorner.Parent = textBox

local createButton = Instance.new("TextButton")
createButton.Name = "CreateButton"
createButton.Size = UDim2.new(0, 280, 0, 35)
createButton.Position = UDim2.new(0, 10, 0, 115)
createButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
createButton.BorderSizePixel = 0
createButton.Text = "CREAR CLON"
createButton.TextColor3 = Color3.fromRGB(255, 255, 255)
createButton.TextSize = 14
createButton.Font = Enum.Font.GothamBold
createButton.Parent = mainFrame

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 4)
buttonCorner.Parent = createButton

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(0, 280, 0, 20)
statusLabel.Position = UDim2.new(0, 10, 1, 5)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Presiona X para abrir/cerrar"
statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
statusLabel.TextSize = 12
statusLabel.Font = Enum.Font.Gotham
statusLabel.Parent = mainFrame

-- ===== FUNCIÓN PARA CREAR CLON =====
local function createClone(userId)
	-- Eliminar clon anterior si existe
	if clone then
		clone:Destroy()
		clone = nil
		cloneHumanoid = nil
		cloneHRP = nil
	end
	
	-- Crear nuevo clon
	local success, errorMsg = pcall(function()
		clone = Players:CreateHumanoidModelFromUserId(userId)
	end)
	
	if not success then
		statusLabel.Text = "❌ Error: ID inválido"
		statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		wait(2)
		statusLabel.Text = "Presiona X para abrir/cerrar"
		statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		return false
	end
	
	clone.Name = "VisualClone"
	clone.Parent = workspace
	
	cloneHumanoid = clone:WaitForChild("Humanoid")
	cloneHRP = clone:WaitForChild("HumanoidRootPart")
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
	
	-- Copiar accesorios del jugador clonado
	task.spawn(function()
		local targetPlayer = Players:GetPlayerByUserId(userId)
		if targetPlayer and targetPlayer.Character then
			for _, obj in ipairs(targetPlayer.Character:GetChildren()) do
				if obj:IsA("Accessory") then
					local cloneAccessory = obj:Clone()
					cloneAccessory.Parent = clone
				end
			end
		end
	end)
	
	-- Posicionar clon
	cloneHRP.CFrame = hrp.CFrame * OFFSET
	
	-- Sincronizar animaciones
	task.wait(0.1)
	syncAnimator()
	
	statusLabel.Text = "✓ Clon creado exitosamente"
	statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	
	return true
end

-- ===== SINCRONIZAR ANIMACIONES =====
function syncAnimator()
	local srcAnimator = humanoid:FindFirstChildOfClass("Animator")
	
	if not srcAnimator then
		return
	end
	
	RunService.RenderStepped:Connect(function()
		if not clone or not cloneHumanoid then return end
		
		local dstAnimator = cloneHumanoid:FindFirstChildOfClass("Animator")
		if not dstAnimator then return end
		
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

-- ===== EVENTO DEL BOTÓN =====
createButton.MouseButton1Click:Connect(function()
	local userId = tonumber(textBox.Text)
	
	if not userId then
		statusLabel.Text = "❌ Por favor ingresa un ID válido"
		statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		wait(2)
		statusLabel.Text = "Presiona X para abrir/cerrar"
		statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		return
	end
	
	createButton.Text = "CREANDO..."
	createButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	
	local success = createClone(userId)
	
	wait(0.5)
	createButton.Text = "CREAR CLON"
	createButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
	
	if success then
		wait(1.5)
		mainFrame.Visible = false
		statusLabel.Text = "Presiona X para abrir/cerrar"
		statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	end
end)

-- ===== TOGGLE GUI CON X =====
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	
	if input.KeyCode == Enum.KeyCode.X then
		mainFrame.Visible = not mainFrame.Visible
	end
	
	-- ===== TOGGLE SEGUIMIENTO CON Z =====
	if input.KeyCode == Enum.KeyCode.Z then
		if not clone then return end
		
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

-- ===== CREAR CLON INICIAL =====
createClone(player.UserId)

-- ===== MOVIMIENTO =====
local currentCFrame = nil
RunService.RenderStepped:Connect(function()
	if not clone or not clone.PrimaryPart then return end
	
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

print("✓ Visual Clone Script cargado correctamente")
print("Controles:")
print("  X = Abrir/Cerrar GUI")
print("  Z = Congelar/Seguir clon")
