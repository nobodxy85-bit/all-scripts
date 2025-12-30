-- VISUAL CLONE + ANIMACIONES + SELECTOR R6/R15 + GUI X
-- Creator: Nobodxy85-bit

-- ===== SERVICIOS =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- ===== CONFIG =====
local OFFSET = CFrame.new(-5,0,0)
local SMOOTHNESS = 0.15

-- ===== ESTADO =====
local following = true
local frozenPosition
local lastPlayerCFrame
local currentCFrame

local clone
local cloneHumanoid
local cloneRoot
local animConnection

local selectedRig = "AUTO" -- AUTO / R6 / R15

-- ===== CHARACTER =====
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")

-- ===== UTIL =====
local function isR6(char)
	return char:FindFirstChild("Torso") ~= nil
end

-- ===== GUI =====
local gui = Instance.new("ScreenGui")
gui.Name = "VisualCloneGUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0,260,0,200)
frame.Position = UDim2.new(0.5,-130,0.5,-100)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.BorderSizePixel = 0
frame.Active = false
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,30)
title.BackgroundTransparency = 1
title.Text = "VISUAL CLONE"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Parent = frame

-- ===== USER ID =====
local idBox = Instance.new("TextBox")
idBox.Size = UDim2.new(1,-20,0,32)
idBox.Position = UDim2.new(0,10,0,40)
idBox.PlaceholderText = "UserId (vacío = tú)"
idBox.Text = ""
idBox.ClearTextOnFocus = false
idBox.BackgroundColor3 = Color3.fromRGB(45,45,45)
idBox.TextColor3 = Color3.new(1,1,1)
idBox.Font = Enum.Font.Gotham
idBox.TextSize = 14
idBox.Parent = frame
Instance.new("UICorner", idBox).CornerRadius = UDim.new(0,6)

-- ===== SELECTOR RIG =====
local rigLabel = Instance.new("TextLabel")
rigLabel.Size = UDim2.new(1,-20,0,20)
rigLabel.Position = UDim2.new(0,10,0,80)
rigLabel.BackgroundTransparency = 1
rigLabel.Text = "Tipo de cuerpo:"
rigLabel.TextColor3 = Color3.fromRGB(200,200,200)
rigLabel.Font = Enum.Font.Gotham
rigLabel.TextSize = 13
rigLabel.TextXAlignment = Enum.TextXAlignment.Left
rigLabel.Parent = frame

local rigButton = Instance.new("TextButton")
rigButton.Size = UDim2.new(1,-20,0,28)
rigButton.Position = UDim2.new(0,10,0,100)
rigButton.Text = "AUTO"
rigButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
rigButton.TextColor3 = Color3.new(1,1,1)
rigButton.Font = Enum.Font.GothamBold
rigButton.TextSize = 14
rigButton.Parent = frame
Instance.new("UICorner", rigButton).CornerRadius = UDim.new(0,6)

rigButton.MouseButton1Click:Connect(function()
	if selectedRig == "AUTO" then
		selectedRig = "R6"
	elseif selectedRig == "R6" then
		selectedRig = "R15"
	else
		selectedRig = "AUTO"
	end
	rigButton.Text = selectedRig
end)

-- ===== BOTÓN =====
local createBtn = Instance.new("TextButton")
createBtn.Size = UDim2.new(1,-20,0,32)
createBtn.Position = UDim2.new(0,10,0,140)
createBtn.Text = "CREAR CLON"
createBtn.BackgroundColor3 = Color3.fromRGB(0,170,255)
createBtn.TextColor3 = Color3.new(1,1,1)
createBtn.Font = Enum.Font.GothamBold
createBtn.TextSize = 14
createBtn.Parent = frame
Instance.new("UICorner", createBtn).CornerRadius = UDim.new(0,6)

-- ===== ANIMACIONES =====
local function syncAnimator()
	if animConnection then animConnection:Disconnect() end

	local srcAnimator = humanoid:FindFirstChildOfClass("Animator")
	if not srcAnimator or not cloneHumanoid then return end
	local dstAnimator = cloneHumanoid:FindFirstChildOfClass("Animator")
	if not dstAnimator then return end

	animConnection = RunService.RenderStepped:Connect(function()
		for _,src in ipairs(srcAnimator:GetPlayingAnimationTracks()) do
			local found = false
			for _,dst in ipairs(dstAnimator:GetPlayingAnimationTracks()) do
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
				local t = dstAnimator:LoadAnimation(anim)
				t:Play(0,1,src.Speed)
			end
		end
	end)
end

-- ===== CREAR CLON =====
local function createClone(userId)
	if clone then clone:Destroy() end

	local rigToUse = selectedRig
	if rigToUse == "AUTO" then
		rigToUse = isR6(character) and "R6" or "R15"
	end

	if rigToUse == "R6" then
		clone = character:Clone()
	else
		local ok, model = pcall(function()
			return Players:CreateHumanoidModelFromUserId(userId)
		end)
		if not ok or not model then return end
		clone = model
	end

	clone.Name = "VisualClone"
	clone.Parent = workspace

	cloneHumanoid = clone:FindFirstChildOfClass("Humanoid")
	cloneRoot = clone:FindFirstChild("HumanoidRootPart") or clone:FindFirstChild("Torso")
	if not cloneHumanoid or not cloneRoot then return end

	clone.PrimaryPart = cloneRoot
	cloneHumanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

	for _,v in ipairs(clone:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CanCollide = false
			v.Transparency = 0.2
			v.Anchored = false
		end
	end

	cloneRoot.Anchored = true
	cloneRoot.CFrame = hrp.CFrame * OFFSET

	task.wait()
	syncAnimator()
end

-- ===== BOTÓN =====
createBtn.MouseButton1Click:Connect(function()
	local id = tonumber(idBox.Text) or player.UserId
	createClone(id)
end)

-- ===== TOGGLES =====
UserInputService.InputBegan:Connect(function(input,gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.X then
		frame.Visible = not frame.Visible
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

-- ===== AUTO =====
createClone(player.UserId)
