-- VISUAL CLONE CON ANIMACIONES + TOGGLE Z + GUI TOGGLE X
-- Creator = Nobodxy85-bit
-- FINAL FIX

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
local frozenPosition
local lastPlayerCFrame
local currentCFrame

local clone
local cloneHumanoid
local cloneRoot

-- ===== CHARACTER =====
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")

-- ===== UTIL =====
local function isR6(char)
	return char:FindFirstChild("Torso") ~= nil
end

-- ===== GUI =====
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CloneConfigGUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 180)
mainFrame.Position = UDim2.new(0.5, -150, 0.5, -90)
mainFrame.BackgroundColor3 = Color3.fromRGB(35,35,35)
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0,8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,35)
title.BackgroundTransparency = 1
title.Text = "VISUAL CLONE"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Parent = mainFrame

local textBox = Instance.new("TextBox")
textBox.Size = UDim2.new(0,280,0,30)
textBox.Position = UDim2.new(0,10,0,45)
textBox.Text = tostring(player.UserId)
textBox.PlaceholderText = "UserId del jugador"
textBox.TextColor3 = Color3.new(1,1,1)
textBox.BackgroundColor3 = Color3.fromRGB(50,50,50)
textBox.ClearTextOnFocus = false
textBox.Parent = mainFrame
Instance.new("UICorner", textBox).CornerRadius = UDim.new(0,6)

local createButton = Instance.new("TextButton")
createButton.Size = UDim2.new(0,280,0,35)
createButton.Position = UDim2.new(0,10,0,85)
createButton.Text = "CREAR CLON"
createButton.BackgroundColor3 = Color3.fromRGB(0,170,255)
createButton.TextColor3 = Color3.new(1,1,1)
createButton.Parent = mainFrame
Instance.new("UICorner", createButton).CornerRadius = UDim.new(0,6)

local info = Instance.new("TextLabel")
info.Size = UDim2.new(1,0,0,30)
info.Position = UDim2.new(0,0,0,130)
info.BackgroundTransparency = 1
info.Text = "X = GUI | Z = Freeze"
info.TextColor3 = Color3.fromRGB(180,180,180)
info.TextSize = 12
info.Parent = mainFrame

-- ===== DRAG GUI =====
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

-- ===== ANIMACIONES =====
local animConnection
local function syncAnimator()
	if animConnection then animConnection:Disconnect() end

	local srcAnimator = humanoid:FindFirstChildOfClass("Animator")
	if not srcAnimator then return end

	animConnection = RunService.RenderStepped:Connect(function()
		if not cloneHumanoid then return end
		local dstAnimator = cloneHumanoid:FindFirstChildOfClass("Animator")
		if not dstAnimator then return end

		for _,track in ipairs(srcAnimator:GetPlayingAnimationTracks()) do
			local found = false
			for _,t in ipairs(dstAnimator:GetPlayingAnimationTracks()) do
				if t.Animation.AnimationId == track.Animation.AnimationId then
					found = true
					t.TimePosition = track.TimePosition
				end
			end
			if not found then
				local anim = Instance.new("Animation")
				anim.AnimationId = track.Animation.AnimationId
				dstAnimator:LoadAnimation(anim):Play()
			end
		end
	end)
end

-- ===== CREAR CLON =====
local function createClone(userId)
	if clone then clone:Destroy() end

	if isR6(character) then
		clone = character:Clone()
	else
		local success, model = pcall(function()
			return Players:CreateHumanoidModelFromUserId(userId)
		end)
		if not success or not model then return end
		clone = model
	end

	clone.Name = "VisualClone"
	clone.Parent = workspace

	cloneHumanoid = clone:FindFirstChildOfClass("Humanoid")
	cloneRoot = clone:FindFirstChild("HumanoidRootPart") or clone:FindFirstChild("Torso")
	if not cloneRoot then return end

	clone.PrimaryPart = cloneRoot
	cloneRoot.Anchored = true
	cloneRoot.CFrame = hrp.CFrame * OFFSET

	for _,v in ipairs(clone:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CanCollide = false
			v.Transparency = 0.2
		end
	end

	syncAnimator()
end

-- ===== BOTÓN =====
createButton.MouseButton1Click:Connect(function()
	local id = tonumber(textBox.Text)
	if not id then
		id = player.UserId
	end
	createClone(id)
end)

-- ===== TOGGLES =====
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end

	if input.KeyCode == Enum.KeyCode.X then
		mainFrame.Visible = not mainFrame.Visible
	elseif input.KeyCode == Enum.KeyCode.Z and cloneRoot then
		following = not following
		if not following then
			frozenPosition = cloneRoot.Position
			lastPlayerCFrame = hrp.CFrame
		end
	end
end)

-- ===== MOVIMIENTO =====
RunService.RenderStepped:Connect(function()
	if not cloneRoot then return end

	local target
	if following then
		target = hrp.CFrame * OFFSET
	else
		local delta = lastPlayerCFrame:Inverse() * hrp.CFrame
		target = CFrame.new(frozenPosition) * (delta - delta.Position)
		lastPlayerCFrame = hrp.CFrame
	end

	currentCFrame = currentCFrame and currentCFrame:Lerp(target, SMOOTHNESS) or target
	cloneRoot.CFrame = currentCFrame
end)

-- ===== INICIO =====
createClone(player.UserId)
