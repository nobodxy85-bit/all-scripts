-- VISUAL CLONE CON ANIMACIONES + TOGGLE Z + GUI TOGGLE X
-- Creator = Nobodxy85-bit
-- FIXED by ChatGPT

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
mainFrame.Size = UDim2.new(0,300,0,150)
mainFrame.Position = UDim2.new(0.5,-150,0.5,-75)
mainFrame.BackgroundColor3 = Color3.fromRGB(35,35,35)
mainFrame.Parent = screenGui

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0,8)

local createButton = Instance.new("TextButton")
createButton.Size = UDim2.new(0,280,0,35)
createButton.Position = UDim2.new(0,10,0,100)
createButton.Text = "CREAR CLON"
createButton.Parent = mainFrame

-- ===== DRAG GUI (FUNCIONA CON ESC) =====
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
			end
		end
	end

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			mainFrame.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)

-- ===== SINCRONIZAR ANIMACIONES =====
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
			if not dstAnimator:FindFirstChild(track.Animation.AnimationId) then
				local anim = Instance.new("Animation")
				anim.AnimationId = track.Animation.AnimationId
				local t = dstAnimator:LoadAnimation(anim)
				t:Play()
			end
		end
	end
end)

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
	createClone(player.UserId)
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

-- ===== INICIAL =====
createClone(player.UserId)
