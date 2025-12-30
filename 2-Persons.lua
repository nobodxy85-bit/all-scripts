-- VISUAL CLONE CON ANIMACIONES + TOGGLE Z + GUI
-- Creator = Nobodxy85-bit
-- Fixed by Chatgpt

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- CONFIG
local OFFSET = CFrame.new(-5, 0, 0)
local SMOOTHNESS = 0.15

-- ESTADO
local following = true
local frozenPosition
local lastPlayerCFrame
local currentCFrame

local clone
local cloneHumanoid
local cloneHRP

-- CHARACTER
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")

-- ===== GUI =====
local gui = Instance.new("ScreenGui", player.PlayerGui)
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,300,0,200)
frame.Position = UDim2.new(0.5,-150,0.5,-100)
frame.BackgroundColor3 = Color3.fromRGB(35,35,35)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,30)
title.Text = "VISUAL CLONE"
title.TextColor3 = Color3.new(1,1,1)
title.BackgroundTransparency = 1

local idBox = Instance.new("TextBox", frame)
idBox.Size = UDim2.new(0,280,0,30)
idBox.Position = UDim2.new(0,10,0,40)
idBox.Text = tostring(player.UserId)
idBox.PlaceholderText = "UserId del jugador"
idBox.BackgroundColor3 = Color3.fromRGB(50,50,50)
idBox.TextColor3 = Color3.new(1,1,1)

local createBtn = Instance.new("TextButton", frame)
createBtn.Size = UDim2.new(0,280,0,30)
createBtn.Position = UDim2.new(0,10,0,80)
createBtn.Text = "CREAR CLON"
createBtn.BackgroundColor3 = Color3.fromRGB(0,170,255)

local bodyLabel = Instance.new("TextLabel", frame)
bodyLabel.Size = UDim2.new(0,280,0,20)
bodyLabel.Position = UDim2.new(0,10,0,115)
bodyLabel.Text = "Tipo de cuerpo:"
bodyLabel.TextColor3 = Color3.new(1,1,1)
bodyLabel.BackgroundTransparency = 1
bodyLabel.TextXAlignment = Enum.TextXAlignment.Left

local bodyType = "R15"

local r15Btn = Instance.new("TextButton", frame)
r15Btn.Size = UDim2.new(0,135,0,25)
r15Btn.Position = UDim2.new(0,10,0,140)
r15Btn.Text = "R15"
r15Btn.BackgroundColor3 = Color3.fromRGB(0,170,255)

local r6Btn = Instance.new("TextButton", frame)
r6Btn.Size = UDim2.new(0,135,0,25)
r6Btn.Position = UDim2.new(0,155,0,140)
r6Btn.Text = "R6"
r6Btn.BackgroundColor3 = Color3.fromRGB(60,60,60)

r15Btn.MouseButton1Click:Connect(function()
	bodyType = "R15"
	r15Btn.BackgroundColor3 = Color3.fromRGB(0,170,255)
	r6Btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
end)

r6Btn.MouseButton1Click:Connect(function()
	bodyType = "R6"
	r6Btn.BackgroundColor3 = Color3.fromRGB(0,170,255)
	r15Btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
end)

-- ===== CREAR CLON =====
local function createClone(userId)
	if clone then clone:Destroy() end

	local model
	if bodyType == "R6" then
		local desc = Players:GetHumanoidDescriptionFromUserId(userId)
		desc.RigType = Enum.HumanoidRigType.R6
		model = Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R6)
	else
		model = Players:CreateHumanoidModelFromUserId(userId)
	end

	if not model then return end

	clone = model
	clone.Name = "VisualClone"
	clone.Parent = workspace

	cloneHumanoid = clone:WaitForChild("Humanoid")
	cloneHRP = clone:WaitForChild("HumanoidRootPart")
	clone.PrimaryPart = cloneHRP

	cloneHumanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

	for _,v in ipairs(clone:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CanCollide = false
			v.Transparency = 0.2
			v.Anchored = (v == cloneHRP)
		end
	end

	-- Accesorios
	for _,obj in ipairs(character:GetChildren()) do
		if obj:IsA("Accessory") then
			obj:Clone().Parent = clone
		end
	end

	-- Animaciones
	local srcAnimator = humanoid:FindFirstChildOfClass("Animator")
	local dstAnimator = cloneHumanoid:FindFirstChildOfClass("Animator")

	RunService.RenderStepped:Connect(function()
		if not srcAnimator or not dstAnimator then return end
		for _,src in ipairs(srcAnimator:GetPlayingAnimationTracks()) do
			local found = false
			for _,dst in ipairs(dstAnimator:GetPlayingAnimationTracks()) do
				if dst.Animation.AnimationId == src.Animation.AnimationId then
					dst.TimePosition = src.TimePosition
					dst:AdjustSpeed(src.Speed)
					found = true
				end
			end
			if not found then
				local anim = Instance.new("Animation")
				anim.AnimationId = src.Animation.AnimationId
				dstAnimator:LoadAnimation(anim):Play()
			end
		end
	end)
end

createBtn.MouseButton1Click:Connect(function()
	local id = tonumber(idBox.Text) or player.UserId
	createClone(id)
end)

-- ===== TOGGLE Z =====
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.Z and cloneHRP then
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
