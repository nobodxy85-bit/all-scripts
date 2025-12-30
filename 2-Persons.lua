-- VISUAL CLONE CON ANIMACIONES + TOGGLE Z + GUI TOGGLE X
-- Creator = Nobodxy85-bit
-- Fusionado y corregido

-- ===== SERVICIOS =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- ===== CONFIG =====
local OFFSET = CFrame.new(-5, 0, 0)
local SMOOTHNESS = 0.15

-- ===== ESTADO =====
local following = true
local frozenPosition = nil
local lastPlayerCFrame = nil

local clone = nil
local cloneHumanoid = nil
local cloneHRP = nil
local currentCFrame = nil

-- ===== CHARACTER =====
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")

-- ===== DETECTAR R6 =====
local function isR6(char)
	return char:FindFirstChild("Torso") ~= nil
end

-- ===== GUI =====
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CloneConfigGUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 150)
mainFrame.Position = UDim2.new(0.5, -150, 0.5, -75)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
mainFrame.Parent = screenGui

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 40)
titleLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
titleLabel.BorderSizePixel = 0
titleLabel.Text = "VISUAL CLONE CONFIG"
titleLabel.TextColor3 = Color3.new(1,1,1)
titleLabel.TextSize = 16
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = mainFrame
Instance.new("UICorner", titleLabel).CornerRadius = UDim.new(0, 8)

local inputLabel = Instance.new("TextLabel")
inputLabel.Size = UDim2.new(0, 280, 0, 20)
inputLabel.Position = UDim2.new(0, 10, 0, 50)
inputLabel.BackgroundTransparency = 1
inputLabel.Text = "User ID del jugador:"
inputLabel.TextColor3 = Color3.fromRGB(200,200,200)
inputLabel.TextSize = 14
inputLabel.Font = Enum.Font.Gotham
inputLabel.TextXAlignment = Enum.TextXAlignment.Left
inputLabel.Parent = mainFrame

local textBox = Instance.new("TextBox")
textBox.Size = UDim2.new(0, 280, 0, 35)
textBox.Position = UDim2.new(0, 10, 0, 75)
textBox.BackgroundColor3 = Color3.fromRGB(50,50,50)
textBox.BorderColor3 = Color3.fromRGB(100,100,100)
textBox.Text = tostring(player.UserId)
textBox.PlaceholderText = "Ingresa User ID..."
textBox.TextColor3 = Color3.new(1,1,1)
textBox.TextSize = 14
textBox.Font = Enum.Font.Gotham
textBox.ClearTextOnFocus = false
textBox.Parent = mainFrame
Instance.new("UICorner", textBox).CornerRadius = UDim.new(0, 4)

local createButton = Instance.new("TextButton")
createButton.Size = UDim2.new(0, 280, 0, 35)
createButton.Position = UDim2.new(0, 10, 0, 115)
createButton.BackgroundColor3 = Color3.fromRGB(0,170,255)
createButton.Text = "CREAR CLON"
createButton.TextColor3 = Color3.new(1,1,1)
createButton.TextSize = 14
createButton.Font = Enum.Font.GothamBold
createButton.Parent = mainFrame
Instance.new("UICorner", createButton).CornerRadius = UDim.new(0, 4)

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0, 280, 0, 20)
statusLabel.Position = UDim2.new(0, 10, 1, 5)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Presiona X para abrir/cerrar"
statusLabel.TextColor3 = Color3.fromRGB(150,150,150)
statusLabel.TextSize = 12
statusLabel.Font = Enum.Font.Gotham
statusLabel.Parent = mainFrame

-- ===== GUI DRAG (FUNCIONA CON ESC) =====
do
	local dragging, dragStart, startPos

	mainFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = mainFrame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			mainFrame.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end

-- ===== SINCRONIZAR ANIMACIONES =====
local function syncAnimator()
	local srcAnimator = humanoid:FindFirstChildOfClass("Animator")
	if not srcAnimator then return end

	RunService.RenderStepped:Connect(function()
		if not cloneHumanoid then return end
		local dstAnimator = cloneHumanoid:FindFirstChildOfClass("Animator")
		if not dstAnimator then return end

		for _, src in ipairs(srcAnimator:GetPlayingAnimationTracks()) do
			local found = false
			for _, dst in ipairs(dstAnimator:GetPlayingAnimationTracks()) do
				if dst.Animation.AnimationId == src.Animation.AnimationId then
					dst.TimePosition = src.TimePosition
					dst:AdjustSpeed(src.Speed)
					found = true
				end
			end
			if not found then
				local anim = Instance.new("Animation")
				anim.AnimationId = src.Animation.AnimationId
				local t = dstAnimator:LoadAnimation(anim)
				t:Play(0,1,src.Speed)
			end
		end
	end)
end

-- ===== CREAR CLON (R6 / R15) =====
local function createClone(userId)
	if clone then clone:Destroy() end

	if isR6(character) then
		clone = character:Clone()
		clone.Parent = workspace
		cloneHumanoid = clone:FindFirstChildOfClass("Humanoid")
		cloneHRP = clone:FindFirstChild("Torso")
	else
		clone = Players:CreateHumanoidModelFromUserId(userId)
		clone.Parent = workspace
		cloneHumanoid = clone:WaitForChild("Humanoid")
		cloneHRP = clone:WaitForChild("HumanoidRootPart")
	end

	clone.Name = "VisualClone"
	clone.PrimaryPart = cloneHRP
	cloneHumanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

	for _, v in ipairs(clone:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CanCollide = false
			v.Transparency = 0.2
			v.Anchored = false
		end
	end

	cloneHRP.Anchored = true
	cloneHRP.CFrame = hrp.CFrame * OFFSET

	task.wait()
	syncAnimator()

	statusLabel.Text = "✓ Clon creado (" .. (isR6(character) and "R6" or "R15") .. ")"
	statusLabel.TextColor3 = Color3.fromRGB(100,255,100)
end

-- ===== BOTÓN =====
createButton.MouseButton1Click:Connect(function()
	local id = tonumber(textBox.Text)
	if not id then return end
	createClone(id)
end)

-- ===== TOGGLES X / Z =====
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.X then
		mainFrame.Visible = not mainFrame.Visible
	elseif input.KeyCode == Enum.KeyCode.Z and cloneHRP then
		following = not following
		if not following then
			frozenPosition = cloneHRP.Position
			lastPlayerCFrame = hrp.CFrame
		end
	end
end)

-- ===== MOVIMIENTO =====
RunService.RenderStepped:Connect(function()
	if not cloneHRP then return end
	local target

	if following then
		target = hrp.CFrame * OFFSET
	else
		local delta = lastPlayerCFrame:Inverse() * hrp.CFrame
		target = CFrame.new(frozenPosition) * (delta - delta.Position)
		lastPlayerCFrame = hrp.CFrame
	end

	currentCFrame = currentCFrame and currentCFrame:Lerp(target, SMOOTHNESS) or target
	cloneHRP.CFrame = currentCFrame
end)

-- ===== INICIAL =====
createClone(player.UserId)
