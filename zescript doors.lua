-- Credits ZeScript
if getgenv().ZeScriptLoaded then
    warn("ZeScript is already running! Please destroy the existing instance first.")
    return
end
getgenv().ZeScriptLoaded = true
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Window = nil
local function safeCall(func, errorContext)
    local success, err = pcall(func)
    if not success then
        local errorMsg = "[ZeScript Error - " .. (errorContext or "Unknown") .. "]: " .. tostring(err)
        if Window and Window.Notify then
            Window:Notify({
                Text = errorMsg,
                Duration = 5,
                Type = "Error"
            })
        else
            warn(errorMsg)
        end
    end
    return success
end
local httpRequest = (syn and syn.request) or http_request or request
if not httpRequest then
    warn("Your executor doesn't support HTTP requests!")
end
local DISCORD_API_URL = "https://5e6a4ce1-65e1-49da-a450-ac983707fc3b-00-s6e0zpq7bs82.janeway.replit.dev:3000/"
local GAME_ID = tostring(game.JobId)
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/XasonYTB/XaLib/refs/heads/main/NewContentTesting"))() 
local minSize = Vector2.new(500, 400)
local defaultSize = Vector2.new(700, 500)
Window = Library:CreateWindow({
    Title = "ZeScript's Doors",
    Size = UserInputService.TouchEnabled and minSize or defaultSize,
    MinSize = minSize,
    MaxSize = Vector2.new(900, 700),
    Keybind = Enum.KeyCode.RightShift,
    Theme = "Purple"
})

local hookSupported = false
do
    local ok, err = pcall(function()
        -- getrawmetatable requires that the executor exposes it
        local mt = getrawmetatable(game)
        if not mt then error("getrawmetatable returned nil") end

        local realNamecall = mt.__namecall
        if not realNamecall then error("__namecall is nil") end

        -- hookmetamethod is the only reliable way to hook __namecall;
        -- hookfunction on a metamethod doesn't work on most executors
        if not hookmetamethod then error("hookmetamethod is nil") end

        -- Actually attempt the hook and immediately restore
        local restored = false
        local old
        old = hookmetamethod(game, "__namecall", function(self, ...)
            return old(self, ...)  -- pure passthrough
        end)

        -- If we reached this line the hook succeeded
        hookSupported = true

        -- Restore the original immediately
        pcall(function()
            hookmetamethod(game, "__namecall", old)
        end)
    end)

    if not ok then
        warn("[ZeScript UNC] __namecall hook test FAILED: " .. tostring(err))
    end

    task.delay(1, function()
        if hookSupported then
            Window:Notify({ Text = "✅ Hook support detected — all features available", Duration = 4, Type = "Success" })
        else
            Window:Notify({ Text = "⚠️ No hook support — Some settings wont appear on this executor (Hah dogshit executor nob)", Duration = 7, Type = "Warning" })
        end
    end)
end

local currentFloor = "Unknown"
local function detectFloor()
    safeCall(function()
        local gameData = ReplicatedStorage:FindFirstChild("GameData")
        if gameData then
            local floorValue = gameData:FindFirstChild("Floor")
            if floorValue then
                currentFloor = floorValue.Value
            end
        end
    end, "Floor Detection")
    return currentFloor
end
currentFloor = detectFloor()

local MainCategory     = Window:CreateCategory("Main",     "⭐")
local ExploitCategory  = Window:CreateCategory("Exploits", "⚡")
local VisualCategory   = Window:CreateCategory("Visual",   "👁️")
local SettingsCategory = Window:CreateCategory("Settings", "⚙️")

-- Main tabs (stuff everyone turns on first)
local EssentialsTab  = MainCategory:CreateTab("Essentials", "🔥")
local ProtectionTab  = MainCategory:CreateTab("Protection", "🛡️")

-- Exploit tabs
local UniversalTab   = ExploitCategory:CreateTab("Universal", "🌍")
local InteractTab    = ExploitCategory:CreateTab("Interact",  "🤝")
local HotelTab       = ExploitCategory:CreateTab("Hotel",     "🏨")
local MinesTab       = ExploitCategory:CreateTab("Mines",     "⛏️")

-- Visual tabs
local ESPTab         = VisualCategory:CreateTab("ESP",     "📍")
local DisplayTab     = VisualCategory:CreateTab("Display", "🎨")

local Settings = {
    spoofCrouch       = false,
    antiEyes          = false,
    disableScreech    = false,
    disableSnare      = false,
    objectBypass      = false,
    noAccel           = false,
    autoProxi         = false,
    autoProxiInstant  = true,
    autoProxiKey      = "R",
    proximityReach    = 0,
    doorReach         = false,
    doorReachDistance = 25,
    antiSpeedBypass   = false,
    speed             = false,
    speedValue        = 16,
    minesAnticheat    = false,
    espDoor           = false,
    espObjective      = false,
    espEntity         = false,
    entityNotifier    = false,
    fullbright        = false,
    fov               = 70,
    theme             = "Purple",
    autoLoad          = false,
    godMode           = false
}

local SaveFileName = "ZeScriptDoors_Settings.json"
local function saveSettings()
    local success, err = pcall(function()
        if writefile then
            writefile(SaveFileName, HttpService:JSONEncode(Settings))
        end
    end)
    if not success then
        Window:Notify({ Text = "[Settings Save Error]: " .. tostring(err), Duration = 5, Type = "Error" })
    end
    return success
end
local function loadSettings()
    local success, data = pcall(function()
        if isfile and isfile(SaveFileName) then
            return HttpService:JSONDecode(readfile(SaveFileName))
        end
        return nil
    end)
    if success and data then
        for key, value in pairs(data) do
            if Settings[key] ~= nil then
                Settings[key] = value
            end
        end
        return true
    end
    return false
end

local lightsEnabled = true
local originalLightStates = {}
local frozenPlayers = {}
local spectatingPlayer = nil
local function getDiscordUsername(discordId)
    if discordId == "904343901526192168" then
        return "Xason (Owner)"
    elseif discordId == "1392295124498645104" then
        return "Draco (Tester)"
    else
        return "Unknown User"
    end
end

local function toggleLights(enabled)
    safeCall(function()
        lightsEnabled = enabled
        for _, obj in pairs(game.Workspace:GetDescendants()) do
            if obj:IsA("Light") or obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
                if originalLightStates[obj] == nil then
                    originalLightStates[obj] = obj.Enabled
                end
                obj.Enabled = enabled
            end
        end
    end, "Toggle Lights")
end

local function freezePlayer(playerName, freeze)
    safeCall(function()
        local targetPlayer = Players:FindFirstChild(playerName)
        if targetPlayer and targetPlayer.Character then
            local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.Anchored = freeze
                frozenPlayers[playerName] = freeze
            end
        end
    end, "Freeze Player")
end

local function spectatePlayer(playerName)
    safeCall(function()
        local targetPlayer = Players:FindFirstChild(playerName)
        if targetPlayer and targetPlayer.Character then
            Camera.CameraSubject = targetPlayer.Character.Humanoid
            spectatingPlayer = playerName
            Window:Notify({ Text = "Now spectating " .. playerName, Duration = 3, Type = "Success" })
        else
            Window:Notify({ Text = "Could not spectate " .. playerName, Duration = 3, Type = "Error" })
        end
    end, "Spectate Player")
end

local function stopSpectating()
    safeCall(function()
        if LocalPlayer.Character then
            Camera.CameraSubject = LocalPlayer.Character.Humanoid
            spectatingPlayer = nil
            Window:Notify({ Text = "Stopped spectating", Duration = 2, Type = "Success" })
        end
    end, "Stop Spectating")
end

local discordConnected = false
local commandCheckLoop
local playerUpdateLoop
local function getAllPlayers()
    local playerList = {}
    safeCall(function()
        for _, player in ipairs(Players:GetPlayers()) do
            table.insert(playerList, { name = player.Name, userId = tostring(player.UserId) })
        end
    end, "Get All Players")
    return playerList
end

local function sendToDiscord(endpoint, data)
    if not discordConnected then return false end
    local success, response = pcall(function()
        return httpRequest({
            Url = DISCORD_API_URL .. endpoint,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(data)
        })
    end)
    return success and response.StatusCode == 200
end

local function checkDiscordCommands()
    if not discordConnected then return end
    safeCall(function()
        local success, response = pcall(function()
            return httpRequest({ Url = DISCORD_API_URL .. "/api/commands/" .. GAME_ID, Method = "GET" })
        end)
        if success and response.StatusCode == 200 then
            local data = HttpService:JSONDecode(response.Body)
            for _, cmd in ipairs(data.commands) do
                local senderName = getDiscordUsername(cmd.senderId or "")
                if cmd.type == "kill" then
                    local targetPlayer = Players:FindFirstChild(cmd.target)
                    if targetPlayer then
                        safeCall(function()
                            if targetPlayer == LocalPlayer then
                                LocalPlayer.Character.Humanoid.Health = 0
                            end
                        end, "Discord Kill Command")
                    end
                elseif cmd.type == "notify" then
                    Window:Notify({ Text = senderName .. ": " .. cmd.message, Duration = 15, Type = "Warning" })
                elseif cmd.type == "kick" then
                    if cmd.target == LocalPlayer.Name then
                        task.wait(1)
                        LocalPlayer:Kick("Kicked by " .. senderName)
                    end
                elseif cmd.type == "freeze" then
                    if cmd.target == LocalPlayer.Name then
                        freezePlayer(LocalPlayer.Name, true)
                    end
                elseif cmd.type == "spectate" then
                    if cmd.target ~= LocalPlayer.Name then
                        spectatePlayer(cmd.target)
                    end
                end
            end
        end
    end, "Check Discord Commands")
end

local function registerWithDiscord()
    safeCall(function()
        local success1, response1 = pcall(function()
            return httpRequest({ Url = DISCORD_API_URL, Method = "GET" })
        end)
        if not success1 then
            Window:Notify({ Text = "Can't reach server: " .. tostring(response1), Duration = 5, Type = "Error" })
            return
        end
        local players = getAllPlayers()
        local success2, response2 = pcall(function()
            return httpRequest({
                Url = DISCORD_API_URL .. "/api/register",
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = HttpService:JSONEncode({ gameId = GAME_ID, players = players })
            })
        end)
        if success2 and response2.StatusCode == 200 then
            discordConnected = true
            Window:Notify({ Text = "Log in successful", Duration = 3, Type = "Success" })
            commandCheckLoop = task.spawn(function()
                while discordConnected do task.wait(10); checkDiscordCommands() end
            end)
            playerUpdateLoop = task.spawn(function()
                while discordConnected do
                    task.wait(10)
                    sendToDiscord("/api/players", { gameId = GAME_ID, players = getAllPlayers() })
                end
            end)
        else
            Window:Notify({
                Text = "Registration failed: " .. (success2 and tostring(response2.StatusCode) or tostring(response2)),
                Duration = 5, Type = "Error"
            })
        end
    end, "Register With Discord")
end

registerWithDiscord()

local godModeEnabled = false
local GOD_COLLISION_SIZE = Vector3.new(1.01, 0.5, 0.5)
local godModeSaved = {}  

local function applyGodMode(character)
    safeCall(function()
        local humanoid = character:WaitForChild("Humanoid", 5)
        if not humanoid then return end

        local collision = character:FindFirstChild("Collision", true)
        if not collision or not collision:IsA("BasePart") then
            warn("[ZeScript GodMode] Collision part not found")
            return
        end

        local collisionCrouch = collision:FindFirstChild("CollisionCrouch", true)

        -- Save original state
        godModeSaved = { hipHeight = humanoid.HipHeight, parts = {} }

        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                godModeSaved.parts[part] = {
                    Size       = part.Size,
                    CanCollide = part.CanCollide,
                }
            end
        end

        -- Apply GodMode
        humanoid.HipHeight = 0.05

        collision.Size       = GOD_COLLISION_SIZE
        collision.CanCollide = true
        if collisionCrouch and collisionCrouch:IsA("BasePart") then
            collisionCrouch.Size       = GOD_COLLISION_SIZE
            collisionCrouch.CanCollide = true
        end

        -- Disable CanCollide on everything else
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part ~= collision and part ~= collisionCrouch then
                part.CanCollide = false
            end
        end
    end, "Apply GodMode")
end

local function restoreGodMode(character)
    safeCall(function()
        if not godModeSaved.parts then return end

        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid and godModeSaved.hipHeight then
            humanoid.HipHeight = godModeSaved.hipHeight
        end

        for part, saved in pairs(godModeSaved.parts) do
            if part and part.Parent then
                part.Size       = saved.Size
                part.CanCollide = saved.CanCollide
            end
        end

        godModeSaved = {}
    end, "Restore GodMode")
end

local godModeAutoEnabled  = false
local godModeDistanceLoop = nil
local GODMODE_ENTITY_RANGE = 250

local function enableGodMode()
    safeCall(function()
        local character = LocalPlayer.Character
        if not character or godModeEnabled then return end
        godModeEnabled = true
        applyGodMode(character)
        Window:Notify({ Text = "GodMode Auto-Enabled (Entity nearby)", Duration = 2, Type = "Success" })
    end, "Enable GodMode")
end

local function disableGodMode()
    safeCall(function()
        local character = LocalPlayer.Character
        if not character or not godModeEnabled then return end
        godModeEnabled = false
        restoreGodMode(character)
        Window:Notify({ Text = "GodMode Auto-Disabled (Entity gone)", Duration = 2, Type = "Warning" })
    end, "Disable GodMode")
end

local function checkEntityDistance()
    if not godModeAutoEnabled then return end
    safeCall(function()
        local character = LocalPlayer.Character
        if not character then return end
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local shouldEnable = false
        for _, name in ipairs({"RushMoving", "AmbushMoving", "BackdoorRush"}) do
            local model = workspace:FindFirstChild(name)
            if model then
                local part = model:FindFirstChildWhichIsA("BasePart")
                if part and (hrp.Position - part.Position).Magnitude <= GODMODE_ENTITY_RANGE then
                    shouldEnable = true
                    break
                end
            end
        end
        if shouldEnable and not godModeEnabled then
            enableGodMode()
        elseif not shouldEnable and godModeEnabled then
            disableGodMode()
        end
    end, "Check Entity Distance")
end

LocalPlayer.CharacterAdded:Connect(function(character)
    safeCall(function()
        if godModeEnabled then
            godModeEnabled = false  -- reset so applyGodMode won't early-return
            task.wait(0.5)
            enableGodMode()
        end
    end, "Character Added - GodMode")
end)

EssentialsTab:Toggle("Auto GodMode", Settings.godMode, function(enabled)
    safeCall(function()
        godModeAutoEnabled = enabled
        Settings.godMode   = enabled
        if enabled then
            godModeDistanceLoop = task.spawn(function()
                while godModeAutoEnabled do task.wait(0.1); checkEntityDistance() end
            end)
        else
            if godModeDistanceLoop then task.cancel(godModeDistanceLoop); godModeDistanceLoop = nil end
            if godModeEnabled then disableGodMode() end
        end
    end, "Auto GodMode Toggle")
end, "Auto-enables GodMode when Rush/Ambush is within 250 studs")

local doorReachEnabled  = false
local doorReachLoop
local doorReachDistance = Settings.doorReachDistance
local doorReachToggle = EssentialsTab:Toggle("Door Reach", Settings.doorReach, function(enabled)
    safeCall(function()
        doorReachEnabled    = enabled
        Settings.doorReach  = enabled
        if enabled then
            doorReachLoop = task.spawn(function()
                while doorReachEnabled do
                    safeCall(function()
                        local char = LocalPlayer and LocalPlayer.Character
                        if not char then return end
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        if not hrp then return end
                        local currentRooms = workspace:FindFirstChild("CurrentRooms")
                        if not currentRooms then return end
                        local rooms = currentRooms:GetChildren()
                        table.sort(rooms, function(a, b)
                            return (tonumber(a.Name) or 0) > (tonumber(b.Name) or 0)
                        end)
                        for i = 1, math.min(3, #rooms) do
                            local targetRoom = rooms[i]
                            if not targetRoom then continue end
                            local door = targetRoom:FindFirstChild("Door")
                            if not door then continue end
                            local remote = door:FindFirstChild("ClientOpen")
                            if not remote then continue end
                            local doorPart = door:IsA("BasePart") and door or door:FindFirstChildWhichIsA("BasePart")
                            if doorPart then
                                local distance = (hrp.Position - doorPart.Position).Magnitude
                                if distance <= doorReachDistance then remote:FireServer() end
                            end
                        end
                    end, "Door Reach Loop")
                    task.wait(0.01)
                end
            end)
        else
            if doorReachLoop then task.cancel(doorReachLoop); doorReachLoop = nil end
        end
    end, "Door Reach Toggle")
end, "Open doors from further away")

EssentialsTab:Slider("Door Reach Distance", 10, 75, Settings.doorReachDistance, function(value)
    safeCall(function()
        doorReachDistance          = value
        Settings.doorReachDistance = value
    end, "Door Reach Distance Slider")
end, "Maximum distance to open doors")

local maxSpeedValue    = currentFloor == "Mines" and 75 or 250
local antiSpeedEnabled = false
local antiSpeedLoop
local clonedCollision
local antiSpeedToggle, antiSpeedToggleId = EssentialsTab:Toggle("AntiSpeed Bypass", Settings.antiSpeedBypass, function(enabled)
    safeCall(function()
        antiSpeedEnabled          = enabled
        Settings.antiSpeedBypass  = enabled
        if enabled then
            local Character   = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local CollisionPart = Character:WaitForChild("CollisionPart")
            clonedCollision             = CollisionPart:Clone()
            clonedCollision.Name        = "_CollisionClone"
            clonedCollision.Massless    = true
            clonedCollision.Parent      = Character
            clonedCollision.CanCollide  = false
            clonedCollision.CanQuery    = false
            clonedCollision.CustomPhysicalProperties = PhysicalProperties.new(0.01, 0.7, 0, 1, 1)
            antiSpeedLoop = task.spawn(function()
                while antiSpeedEnabled do
                    task.wait(0.23)
                    safeCall(function()
                        if clonedCollision then
                            clonedCollision.Massless = false
                            task.wait(0.23)
                            local root = Character:FindFirstChild("HumanoidRootPart")
                            if root and root.Anchored then
                                clonedCollision.Massless = true
                                task.wait(1)
                            end
                            clonedCollision.Massless = true
                        end
                    end, "Anti Speed Loop")
                end
            end)
        else
            antiSpeedEnabled = false
            if antiSpeedLoop then task.cancel(antiSpeedLoop); antiSpeedLoop = nil end
            if clonedCollision then clonedCollision:Destroy(); clonedCollision = nil end
        end
    end, "AntiSpeed Bypass Toggle")
end, "Required for Speed - bypasses anticheat")

local speedEnabled      = false
local originalWalkSpeed = 16
local speedValue        = Settings.speedValue
local speedLoop
EssentialsTab:Toggle("Enable Speed", Settings.speed, function(enabled)
    safeCall(function()
        if enabled and not antiSpeedEnabled then
            Window:Notify({ Text = "Please enable AntiSpeed Bypass first!", Duration = 4, Type = "Warning" })
            speedEnabled   = false
            Settings.speed = false
            return
        end
        speedEnabled   = enabled
        Settings.speed = enabled
        if enabled then
            local Character = LocalPlayer.Character
            if Character then
                local Humanoid = Character:FindFirstChild("Humanoid")
                if Humanoid then originalWalkSpeed = Humanoid.WalkSpeed end
            end
            speedLoop = task.spawn(function()
                while speedEnabled do
                    task.wait(0.1)
                    safeCall(function()
                        local Char = LocalPlayer.Character
                        if Char then
                            local Hum = Char:FindFirstChild("Humanoid")
                            if Hum then Hum.WalkSpeed = speedValue end
                        end
                    end, "Speed Loop")
                end
            end)
        else
            if speedLoop then task.cancel(speedLoop); speedLoop = nil end
            local Char = LocalPlayer.Character
            if Char then
                local Hum = Char:FindFirstChild("Humanoid")
                if Hum then Hum.WalkSpeed = originalWalkSpeed end
            end
        end
    end, "Enable Speed Toggle")
end, "Increase walk speed - requires AntiSpeed Bypass")

EssentialsTab:Slider("Speed Value", 2, maxSpeedValue, math.min(Settings.speedValue, maxSpeedValue), function(value)
    safeCall(function()
        speedValue          = value
        Settings.speedValue = value
    end, "Speed Value Slider")
end, "Set your desired walk speed")

-- Fullbright moved to Essentials (very commonly used)
local fullbrightEnabled  = false
local originalLighting   = {}
local lightingConnection
EssentialsTab:Toggle("Fullbright", Settings.fullbright, function(enabled)
    safeCall(function()
        fullbrightEnabled    = enabled
        Settings.fullbright  = enabled
        local Lighting       = game:GetService("Lighting")
        if enabled then
            originalLighting = {
                Brightness    = Lighting.Brightness,
                ClockTime     = Lighting.ClockTime,
                FogEnd        = Lighting.FogEnd,
                GlobalShadows = Lighting.GlobalShadows,
                Ambient       = Lighting.Ambient
            }
            Lighting.Brightness    = 2
            Lighting.ClockTime     = 14
            Lighting.FogEnd        = 100000
            Lighting.GlobalShadows = false
            Lighting.Ambient       = Color3.fromRGB(178, 178, 178)
            lightingConnection = Lighting.Changed:Connect(function(property)
                if not fullbrightEnabled then return end
                safeCall(function()
                    if property == "Brightness"    and Lighting.Brightness    ~= 2                           then Lighting.Brightness    = 2                           end
                    if property == "ClockTime"     and Lighting.ClockTime     ~= 14                          then Lighting.ClockTime     = 14                          end
                    if property == "FogEnd"        and Lighting.FogEnd        ~= 100000                      then Lighting.FogEnd        = 100000                      end
                    if property == "GlobalShadows" and Lighting.GlobalShadows ~= false                       then Lighting.GlobalShadows = false                       end
                    if property == "Ambient"       and Lighting.Ambient       ~= Color3.fromRGB(178,178,178) then Lighting.Ambient       = Color3.fromRGB(178,178,178) end
                end, "Fullbright Changed Event")
            end)
        else
            if lightingConnection then lightingConnection:Disconnect(); lightingConnection = nil end
            for property, value in pairs(originalLighting) do Lighting[property] = value end
        end
    end, "Fullbright Toggle")
end, "See clearly in dark areas")

local spoofCrouchEnabled = false
local spoofCrouchLoop
local spoofCrouchToggle = ProtectionTab:Toggle("Spoof Crouch", Settings.spoofCrouch, function(enabled)
    safeCall(function()
        spoofCrouchEnabled    = enabled
        Settings.spoofCrouch  = enabled
        if enabled then
            spoofCrouchLoop = task.spawn(function()
                while spoofCrouchEnabled do
                    safeCall(function()
                        ReplicatedStorage.RemotesFolder.Crouch:FireServer(true, true)
                    end, "Spoof Crouch Loop")
                    task.wait(0.32)
                end
            end)
        else
            if spoofCrouchLoop then task.cancel(spoofCrouchLoop); spoofCrouchLoop = nil end
        end
    end, "Spoof Crouch Toggle")
end, "Tricks the game into thinking you're always crouching")

local antiEyesEnabled = false
local antiEyesLoop
local antiEyesToggle = ProtectionTab:Toggle("Anti Eyes", Settings.antiEyes, function(enabled)
    safeCall(function()
        antiEyesEnabled    = enabled
        Settings.antiEyes  = enabled
        if enabled then
            antiEyesLoop = task.spawn(function()
                while antiEyesEnabled do
                    safeCall(function()
                        for _, v in pairs(workspace:GetChildren()) do
                            if v.Name == "Eyes" and v:FindFirstChild("Core") then
                                local core = v.Core
                                if core:FindFirstChild("Ambience") and core.Ambience.Playing then
                                    ReplicatedStorage.RemotesFolder.MotorReplication:FireServer(-650)
                                    break
                                end
                            end
                        end
                    end, "Anti Eyes Loop")
                    task.wait()
                end
            end)
        else
            if antiEyesLoop then task.cancel(antiEyesLoop); antiEyesLoop = nil end
        end
    end, "Anti Eyes Toggle")
end, "Automatically looks away from Eyes")

local screechDisabled       = false
local screechOriginalParent = nil
local screechToggle = ProtectionTab:Toggle("Disable Screech", Settings.disableScreech, function(enabled)
    safeCall(function()
        screechDisabled          = enabled
        Settings.disableScreech  = enabled
        local screech = ReplicatedStorage.Entities:FindFirstChild("Screech")
        if enabled and screech then
            local zeScriptStuff = ReplicatedStorage:FindFirstChild("ZeScript_Stuff")
            if not zeScriptStuff then
                zeScriptStuff = Instance.new("Folder")
                zeScriptStuff.Name   = "ZeScript_Stuff"
                zeScriptStuff.Parent = ReplicatedStorage
            end
            local disabledEntity = zeScriptStuff:FindFirstChild("DisabledEntity")
            if not disabledEntity then
                disabledEntity = Instance.new("Folder")
                disabledEntity.Name   = "DisabledEntity"
                disabledEntity.Parent = zeScriptStuff
            end
            screechOriginalParent = screech.Parent
            screech.Parent        = disabledEntity
        elseif not enabled and screech and screechOriginalParent then
            screech.Parent = screechOriginalParent
        end
    end, "Disable Screech Toggle")
end, "Prevents Screech from spawning")

local snareDisabled = false
local snareHitboxes = {}
local snareToggle = ProtectionTab:Toggle("Disable Snare", Settings.disableSnare, function(enabled)
    safeCall(function()
        snareDisabled          = enabled
        Settings.disableSnare  = enabled
        if enabled then
            for _, room in pairs(workspace.CurrentRooms:GetChildren()) do
                safeCall(function()
                    local assets = room:FindFirstChild("Assets")
                    if assets then
                        for _, snare in pairs(assets:GetChildren()) do
                            if snare.Name == "Snare" then
                                local hitbox = snare:FindFirstChild("Hitbox")
                                if hitbox then
                                    hitbox.CanTouch = false
                                    table.insert(snareHitboxes, hitbox)
                                end
                            end
                        end
                    end
                end, "Disable Snare - Initial")
            end
            task.spawn(function()
                while snareDisabled do
                    task.wait(0.5)
                    safeCall(function()
                        for _, room in pairs(workspace.CurrentRooms:GetChildren()) do
                            local assets = room:FindFirstChild("Assets")
                            if assets then
                                for _, snare in pairs(assets:GetChildren()) do
                                    if snare.Name == "Snare" then
                                        local hitbox = snare:FindFirstChild("Hitbox")
                                        if hitbox and hitbox.CanTouch then
                                            hitbox.CanTouch = false
                                            if not table.find(snareHitboxes, hitbox) then
                                                table.insert(snareHitboxes, hitbox)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end, "Disable Snare Loop")
                end
            end)
        else
            for _, hitbox in pairs(snareHitboxes) do
                safeCall(function()
                    if hitbox and hitbox.Parent then hitbox.CanTouch = true end
                end, "Re-enable Snare")
            end
            snareHitboxes = {}
        end
    end, "Disable Snare Toggle")
end, "Disables Snare traps")

local antiHeartbeatEnabled = false
local antiA90Enabled       = false
local hooksInitialized     = false

local function initHooks()
    if hooksInitialized then return end
    if not hookSupported then
        warn("[ZeScript] initHooks called but hook support is unavailable — skipping")
        return
    end
    local ok, err = pcall(function()
        local HideMonster = ReplicatedStorage:WaitForChild("RemotesFolder"):WaitForChild("HideMonster")
        local A90Remote   = ReplicatedStorage:WaitForChild("RemotesFolder"):WaitForChild("A90")
        -- hookmetamethod is confirmed available by the UNC check
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if method == "FireServer" then
                if antiHeartbeatEnabled and self == HideMonster then
                    print("[HideMonster] Blocked death!")
                    return
                end
                if antiA90Enabled and self == A90Remote then
                    local args = {...}
                    if args[1] == "moved" then
                        print("[A90] Blocked death! Sending didnt instead")
                        return oldNamecall(self, "didnt")
                    end
                end
            end
            return oldNamecall(self, ...)
        end)
        hooksInitialized = true
        print("[ZeScript] Hooks initialized successfully!")
    end)
    if not ok then
        warn("[ZeScript] initHooks FAILED: " .. tostring(err))
    end
end

if hookSupported then
    ProtectionTab:Toggle("Anti Heartbeat Kick", false, function(enabled)
        safeCall(function()
            antiHeartbeatEnabled = enabled
            if enabled then initHooks() end
            Window:Notify({ Text = enabled and "Anti Heartbeat enabled!" or "Anti Heartbeat disabled.", Duration = 3, Type = enabled and "Success" or "Warning" })
        end, "Anti Heartbeat Toggle")
    end, "Blocks Figure's heartbeat minigame from killing you")

    ProtectionTab:Toggle("Anti A-90", false, function(enabled)
        safeCall(function()
            antiA90Enabled = enabled
            if enabled then initHooks() end
            Window:Notify({ Text = enabled and "Anti A-90 enabled!" or "Anti A-90 disabled.", Duration = 3, Type = enabled and "Success" or "Warning" })
        end, "Anti A90 Toggle")
    end, "Replaces A-90 death signal with survival signal")
else
    ProtectionTab:Label("❌ Anti Heartbeat — requires hook support (unsupported executor)")
    ProtectionTab:Label("❌ Anti A-90 — requires hook support (unsupported executor)")
end

local antiGKEnabled        = false
local antiGKLoop           = nil
local isAntiGKActive       = false
local fakeGKCameraConn     = nil
local originalCameraType     = Camera.CameraType
local originalCameraSubject  = Camera.CameraSubject

local function getModelPosition(model)
    if not model then return nil end
    local ok, pivot = pcall(function() return model:GetPivot() end)
    if ok and pivot then return pivot.Position end
    local part = model:FindFirstChildWhichIsA("BasePart", true)
    return part and part.Position or nil
end

local function enableFakeGKCamera(character)
    if fakeGKCameraConn then return end
    local head = character:FindFirstChild("Head")
    if not head then return end
    originalCameraType    = Camera.CameraType
    originalCameraSubject = Camera.CameraSubject
    Camera.CameraType     = Enum.CameraType.Scriptable
    fakeGKCameraConn = RunService.RenderStepped:Connect(function()
        if not head or not head.Parent then return end
        Camera.CFrame = head.CFrame * CFrame.new(0, -2, 0)
    end)
end

local function disableFakeGKCamera()
    if fakeGKCameraConn then
        fakeGKCameraConn:Disconnect()
        fakeGKCameraConn = nil
    end
    Camera.CameraType = originalCameraType
    if originalCameraSubject then Camera.CameraSubject = originalCameraSubject end
end

local function enableAntiGroundskeeper(character)
    safeCall(function()
        if isAntiGKActive then return end
        local humanoid = character:FindFirstChild("Humanoid")
        local hrp      = character:FindFirstChild("HumanoidRootPart")
        if not (humanoid and hrp) then return end
        hrp.CFrame         = hrp.CFrame + Vector3.new(0, 2, 0)
        humanoid.HipHeight = 5
        enableFakeGKCamera(character)
        isAntiGKActive = true
        Window:Notify({ Text = "Anti-Groundskeeper Activated", Duration = 2, Type = "Warning" })
    end)
end

local function disableAntiGroundskeeper(character)
    safeCall(function()
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then humanoid.HipHeight = 2 end
        disableFakeGKCamera()
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CFrame = hrp.CFrame - Vector3.new(0, 2, 0) end
        isAntiGKActive = false
        Window:Notify({ Text = "Anti-Groundskeeper Deactivated", Duration = 2, Type = "Success" })
    end)
end

local function checkGroundskeeper()
    if not antiGKEnabled then return end
    safeCall(function()
        local character = LocalPlayer.Character
        if not character then return end
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local gkFound = false
        for _, room in pairs(workspace.CurrentRooms:GetChildren()) do
            local gk = room:FindFirstChild("Groundskeeper")
            if gk and gk:IsA("Model") then
                local gkPos = getModelPosition(gk)
                if gkPos and (hrp.Position - gkPos).Magnitude <= 300 then
                    gkFound = true; break
                end
            end
        end
        if gkFound and not isAntiGKActive then
            enableAntiGroundskeeper(character)
        elseif not gkFound and isAntiGKActive then
            disableAntiGroundskeeper(character)
        end
    end)
end

ProtectionTab:Toggle("Anti-Groundskeeper", false, function(enabled)
    safeCall(function()
        antiGKEnabled = enabled
        if enabled then
            antiGKLoop = task.spawn(function()
                while antiGKEnabled do task.wait(0.1); checkGroundskeeper() end
            end)
        else
            if antiGKLoop then task.cancel(antiGKLoop); antiGKLoop = nil end
            if isAntiGKActive then
                local character = LocalPlayer.Character
                if character then disableAntiGroundskeeper(character) end
            end
        end
    end)
end)

LocalPlayer.CharacterAdded:Connect(function()
    safeCall(function()
        isAntiGKActive = false
        disableFakeGKCamera()
    end)
end)

local figureGodModeEnabled   = false
local figureGodModeLoop      = nil
local isFigureGodModeActive  = false
local fakeCameraConnection   = nil

local function getFigurePosition(figureRig)
    if not figureRig then return nil end
    local ok, pivot = pcall(function() return figureRig:GetPivot() end)
    if ok and pivot then return pivot.Position end
    local part = figureRig:FindFirstChildWhichIsA("BasePart", true)
    return part and part.Position or nil
end

local function enableFakeCamera(character)
    if fakeCameraConnection then return end
    local head = character:FindFirstChild("Head")
    if not head then return end
    originalCameraType    = Camera.CameraType
    originalCameraSubject = Camera.CameraSubject
    Camera.CameraType     = Enum.CameraType.Scriptable
    fakeCameraConnection  = RunService.RenderStepped:Connect(function()
        if not head or not head.Parent then return end
        Camera.CFrame = head.CFrame * CFrame.new(0, -10, 0)
    end)
end

local function disableFakeCamera()
    if fakeCameraConnection then
        fakeCameraConnection:Disconnect()
        fakeCameraConnection = nil
    end
    Camera.CameraType = originalCameraType
    if originalCameraSubject then Camera.CameraSubject = originalCameraSubject end
end

local function enableFigureGodMode(character)
    safeCall(function()
        if isFigureGodModeActive then return end
        local humanoid = character:FindFirstChild("Humanoid")
        local hrp      = character:FindFirstChild("HumanoidRootPart")
        if not (humanoid and hrp) then return end
        hrp.CFrame         = hrp.CFrame + Vector3.new(0, 13, 0)
        humanoid.HipHeight = 13
        enableFakeCamera(character)
        isFigureGodModeActive = true
        Window:Notify({ Text = "Figure GodMode Activated", Duration = 2, Type = "Warning" })
    end)
end

local function disableFigureGodMode(character)
    safeCall(function()
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then humanoid.HipHeight = 2 end
        disableFakeCamera()
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CFrame = hrp.CFrame - Vector3.new(0, 13, 0) end
        isFigureGodModeActive = false
        Window:Notify({ Text = "Figure GodMode Deactivated", Duration = 2, Type = "Success" })
    end)
end

local function checkFigureDistance()
    if not figureGodModeEnabled then return end
    safeCall(function()
        local character = LocalPlayer.Character
        if not character then return end
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local figureNearby = false
        for _, room in pairs(workspace.CurrentRooms:GetChildren()) do
            local setup = room:FindFirstChild("FigureSetup")
            if setup then
                local rig = setup:FindFirstChild("FigureRig")
                if rig then
                    local pos = getFigurePosition(rig)
                    if pos and (hrp.Position - pos).Magnitude <= 30 then
                        figureNearby = true; break
                    end
                end
            end
        end
        if figureNearby and not isFigureGodModeActive then
            enableFigureGodMode(character)
        elseif not figureNearby and isFigureGodModeActive then
            disableFigureGodMode(character)
        end
    end)
end

UniversalTab:Toggle("Figure GodMode", false, function(enabled)
    safeCall(function()
        figureGodModeEnabled = enabled
        if enabled then
            figureGodModeLoop = task.spawn(function()
                while figureGodModeEnabled do task.wait(0.1); checkFigureDistance() end
            end)
        else
            if figureGodModeLoop then task.cancel(figureGodModeLoop); figureGodModeLoop = nil end
            if isFigureGodModeActive then
                local character = LocalPlayer.Character
                if character then disableFigureGodMode(character) end
            end
        end
    end)
end)

LocalPlayer.CharacterAdded:Connect(function()
    safeCall(function()
        isFigureGodModeActive = false
        disableFakeCamera()
    end)
end)

local antiDupeEnabled         = false
local disabledDupeCollisions  = {}
local antiDupeToggle = UniversalTab:Toggle("Anti-Dupe", false, function(enabled)
    safeCall(function()
        antiDupeEnabled = enabled
        local function processRoom(room)
            safeCall(function()
                local sideroomSpace = room:FindFirstChild("SideroomSpace")
                if sideroomSpace then
                    local collision = sideroomSpace:FindFirstChild("Collision")
                    if collision and collision:IsA("BasePart") and collision.CanCollide then
                        collision.CanCollide  = false
                        collision.CanQuery    = false
                        collision.CanTouch    = false
                        if not table.find(disabledDupeCollisions, collision) then
                            table.insert(disabledDupeCollisions, collision)
                        end
                    end
                end
                local sideroomDupe = room:FindFirstChild("SideroomDupe")
                if sideroomDupe then
                    local doorFake = sideroomDupe:FindFirstChild("DoorFake")
                    if doorFake then
                        local hidden = doorFake:FindFirstChild("Hidden")
                        if hidden and hidden:IsA("BasePart") and hidden.CanCollide then
                            hidden.CanCollide  = false
                            hidden.CanQuery    = false
                            hidden.CanTouch    = false
                            if not table.find(disabledDupeCollisions, hidden) then
                                table.insert(disabledDupeCollisions, hidden)
                            end
                        end
                    end
                    for _, part in pairs(sideroomDupe:GetDescendants()) do
                        if part:IsA("BasePart") and part.Name:lower():find("collision") then
                            part:Destroy()
                        end
                    end
                end
            end, "Anti-Dupe - Room")
        end
        if enabled then
            for _, room in pairs(workspace.CurrentRooms:GetChildren()) do processRoom(room) end
            task.spawn(function()
                while antiDupeEnabled do
                    task.wait(0.5)
                    for _, room in pairs(workspace.CurrentRooms:GetChildren()) do processRoom(room) end
                end
            end)
        else
            for _, part in pairs(disabledDupeCollisions) do
                safeCall(function()
                    if part and part.Parent then
                        part.CanCollide = true; part.CanQuery = true; part.CanTouch = true
                    end
                end, "Re-enable Dupe Collisions")
            end
            disabledDupeCollisions = {}
        end
    end, "Anti-Dupe Toggle")
end, "Disables dupe room collisions")

local objectBypassEnabled = false
local disabledObjects     = {}
local objectBypassToggle = UniversalTab:Toggle("Object Bypass", Settings.objectBypass, function(enabled)
    safeCall(function()
        objectBypassEnabled    = enabled
        Settings.objectBypass  = enabled
        local function processRoom(room)
            safeCall(function()
                local assets = room:FindFirstChild("Assets")
                if not assets then return end
                for _, chandelier in pairs(assets:GetChildren()) do
                    if chandelier.Name == "ChandelierObstruction" then
                        local collision = chandelier:FindFirstChild("Collision")
                        if collision and collision.CanTouch then
                            collision.CanTouch  = false
                            collision.CanQuery  = false
                            if not table.find(disabledObjects, collision) then
                                table.insert(disabledObjects, collision)
                            end
                        end
                    end
                end
                for _, object in pairs(assets:GetDescendants()) do
                    if object:IsA("Model") and object:GetAttribute("LoadModule") == "AnimatedObstacleKill" then
                        for _, part in pairs(object:GetDescendants()) do
                            if part:IsA("BasePart") and part.CanTouch then
                                part.CanTouch  = false
                                part.CanQuery  = false
                                if not table.find(disabledObjects, part) then
                                    table.insert(disabledObjects, part)
                                end
                            end
                        end
                    end
                end
            end, "Object Bypass - Room")
        end
        if enabled then
            for _, room in pairs(workspace.CurrentRooms:GetChildren()) do processRoom(room) end
            task.spawn(function()
                while objectBypassEnabled do
                    task.wait(0.5)
                    for _, room in pairs(workspace.CurrentRooms:GetChildren()) do processRoom(room) end
                end
            end)
        else
            for _, part in pairs(disabledObjects) do
                safeCall(function()
                    if part and part.Parent then part.CanTouch = true; part.CanQuery = true end
                end, "Re-enable Objects")
            end
            disabledObjects = {}
        end
    end, "Object Bypass Toggle")
end, "Disables chandeliers and animated obstacles")

local noAccelEnabled    = false
local noAccelLoop       = nil
local originalHrpProps  = nil
local noAccelToggle = UniversalTab:Toggle("No Acceleration", Settings.noAccel, function(enabled)
    safeCall(function()
        noAccelEnabled    = enabled
        Settings.noAccel  = enabled
        if enabled then
            local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local hrp = Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                originalHrpProps          = hrp.CustomPhysicalProperties
                hrp.CustomPhysicalProperties = PhysicalProperties.new(100, 0.7, 0, 1, 1)
            end
            noAccelLoop = task.spawn(function()
                while noAccelEnabled do
                    task.wait(0.5)
                    safeCall(function()
                        local Char = LocalPlayer and LocalPlayer.Character
                        if Char then
                            local h = Char:FindFirstChild("HumanoidRootPart")
                            if h then
                                local cpp = h.CustomPhysicalProperties
                                if not cpp or cpp.Density ~= 100 then
                                    h.CustomPhysicalProperties = PhysicalProperties.new(100, 0.7, 0, 1, 1)
                                end
                            end
                        end
                    end, "No Accel Loop")
                end
            end)
        else
            if noAccelLoop then task.cancel(noAccelLoop); noAccelLoop = nil end
            local Char = LocalPlayer and LocalPlayer.Character
            if Char then
                local h = Char:FindFirstChild("HumanoidRootPart")
                if h then h.CustomPhysicalProperties = originalHrpProps end
            end
            originalHrpProps = nil
        end
    end, "No Acceleration Toggle")
end, "Removes movement acceleration")

local entityPathingEnabled = false
local savedNodesFolder     = nil
local function setupPathfindNodes()
    safeCall(function()
        local currentRooms = workspace:FindFirstChild("CurrentRooms")
        if not currentRooms then return end
        if not savedNodesFolder then
            savedNodesFolder = workspace:FindFirstChild("Saved_ZeScriptNodes")
            if not savedNodesFolder then
                savedNodesFolder        = Instance.new("Folder")
                savedNodesFolder.Name   = "Saved_ZeScriptNodes"
                savedNodesFolder.Parent = workspace
            end
        end
        for _, room in pairs(currentRooms:GetChildren()) do
            safeCall(function()
                if room:IsA("Model") then
                    local pathfindNodes = room:FindFirstChild("PathfindNodes")
                    if pathfindNodes then
                        local roomNodeName = "Room_" .. room.Name .. "_Nodes"
                        if not savedNodesFolder:FindFirstChild(roomNodeName) then
                            local clonedFolder  = pathfindNodes:Clone()
                            clonedFolder.Name   = roomNodeName
                            for _, part in pairs(clonedFolder:GetDescendants()) do
                                if part:IsA("BasePart") then
                                    part.Transparency = entityPathingEnabled and 0 or 1
                                end
                            end
                            clonedFolder.Parent = savedNodesFolder
                        end
                    end
                end
            end, "Setup Pathfind Nodes - Room " .. tostring(room.Name))
        end
    end, "Setup Pathfind Nodes Main")
end
setupPathfindNodes()

task.spawn(function()
    while true do task.wait(0.01); setupPathfindNodes() end
end)

local entityPathingToggle = UniversalTab:Toggle("Entity Pathing", false, function(enabled)
    safeCall(function()
        entityPathingEnabled = enabled
        if savedNodesFolder then
            for _, nodeFolder in pairs(savedNodesFolder:GetChildren()) do
                for _, part in pairs(nodeFolder:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.Transparency = enabled and 0 or 1
                    end
                end
            end
            Window:Notify({
                Text     = enabled and "Entity pathing nodes now visible!" or "Entity pathing nodes hidden",
                Duration = 2,
                Type     = enabled and "Success" or "Warning"
            })
        else
            Window:Notify({ Text = "No pathfind nodes found yet", Duration = 2, Type = "Warning" })
        end
    end, "Entity Pathing Toggle")
end, "Shows entity path nodes")

local autoFinishDailyEnabled = false
local autoFinishDailyLoop    = nil
local autoFinishDailyToggle = UniversalTab:Toggle("Auto Finish Daily Run", false, function(enabled)
    safeCall(function()
        autoFinishDailyEnabled = enabled
        if enabled then
            Window:Notify({ Text = "[Finish Daily Run]: Go through some rooms — it'll auto-finish everything else after some time", Duration = 8, Type = "Warning" })
            autoFinishDailyLoop = task.spawn(function()
                while autoFinishDailyEnabled do
                    task.wait(1)
                    safeCall(function()
                        local Character = LocalPlayer and LocalPlayer.Character
                        if not Character then return end
                        local hrp = Character:FindFirstChild("HumanoidRootPart")
                        if not hrp then return end
                        local currentRooms = workspace:FindFirstChild("CurrentRooms")
                        if not currentRooms then return end
                        for _, room in pairs(currentRooms:GetChildren()) do
                            local rippleExitDoor = room:FindFirstChild("RippleExitDoor", true)
                            if rippleExitDoor then
                                local doorPart = rippleExitDoor:IsA("BasePart") and rippleExitDoor or rippleExitDoor:FindFirstChildWhichIsA("BasePart", true)
                                if doorPart then
                                    hrp.CFrame = doorPart.CFrame + Vector3.new(0, 3, 0)
                                    Window:Notify({ Text = "Teleported to Daily Run Exit!", Duration = 3, Type = "Success" })
                                end
                            end
                        end
                    end, "Auto Finish Daily Run Loop")
                end
            end)
        else
            if autoFinishDailyLoop then task.cancel(autoFinishDailyLoop); autoFinishDailyLoop = nil end
        end
    end, "Auto Finish Daily Run Toggle")
end, "Automatically finds and teleports to the daily run exit")

loadstring(game:HttpGet("https://raw.githubusercontent.com/ZeScript/ZeScripts/refs/heads/main/Debug"))()

local anticheatManipEnabled  = false
local anticheatManipLoop     = nil
local isAnticheatKeyHeld     = false
local anticheatManipKey      = Enum.KeyCode.T
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    safeCall(function()
        if input.KeyCode == anticheatManipKey and not gameProcessed then isAnticheatKeyHeld = true end
    end, "AntiCheat Manip Input Began")
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    safeCall(function()
        if input.KeyCode == anticheatManipKey then isAnticheatKeyHeld = false end
    end, "AntiCheat Manip Input Ended")
end)

local anticheatManipToggle = UniversalTab:Toggle("AntiCheat Manipulation (Hold T)", false, function(enabled)
    safeCall(function()
        anticheatManipEnabled = enabled
        if enabled then
            anticheatManipLoop = task.spawn(function()
                while anticheatManipEnabled do
                    task.wait(0.00001)
                    safeCall(function()
                        if isAnticheatKeyHeld and LocalPlayer.Character then
                            LocalPlayer.Character:PivotTo(LocalPlayer.Character:GetPivot() + workspace.CurrentCamera.CFrame.LookVector * Vector3.new(1, 0, 1) * -100)
                        end
                    end, "AntiCheat Manip Loop")
                end
            end)
        else
            if anticheatManipLoop then task.cancel(anticheatManipLoop); anticheatManipLoop = nil end
        end
    end, "AntiCheat Manipulation Toggle")
end, "Uses the anticheat to teleport you forward — good for teleporting against tiny walls")

local proximityReach      = Settings.proximityReach
local autoProxiEnabled    = false
local autoProxiLoop
local autoProxiInstant    = Settings.autoProxiInstant
local autoProxiKey        = Enum.KeyCode[Settings.autoProxiKey] or Enum.KeyCode.R
local isAutoProxiKeyHeld  = false
local autoProxiCooldowns  = {}
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    safeCall(function()
        if input.KeyCode == autoProxiKey and not gameProcessed then isAutoProxiKeyHeld = true end
    end, "Input Began")
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    safeCall(function()
        if input.KeyCode == autoProxiKey then isAutoProxiKeyHeld = false end
    end, "Input Ended")
end)

local function shouldInteract(prompt)
    if not prompt or not prompt.Enabled then return false end
    local actionText = (prompt.ActionText or ""):lower()
    if actionText:find("close") then return false end
    if actionText:find("leave") then return false end
    if actionText:find("exit") and not actionText:find("door") then return false end
    if actionText:find("hide") then return false end
    return true
end

local function getAllProximityPrompts()
    local prompts = {}
    safeCall(function()
        local currentRooms = workspace:FindFirstChild("CurrentRooms")
        if currentRooms then
            for _, prompt in pairs(currentRooms:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") then table.insert(prompts, prompt) end
            end
        end
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            for _, prompt in pairs(playerGui:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") then table.insert(prompts, prompt) end
            end
        end
    end, "Get All Proximity Prompts")
    return prompts
end

local function runAutoProxi()
    safeCall(function()
        local prompts = getAllProximityPrompts()
        for _, prompt in pairs(prompts) do
            if shouldInteract(prompt) then
                local promptId = tostring(prompt:GetFullName())
                local now      = tick()
                if autoProxiCooldowns[promptId] and (now - autoProxiCooldowns[promptId]) < 0.1 then continue end
                autoProxiCooldowns[promptId] = now
                task.spawn(function()
                    safeCall(function()
                        if autoProxiInstant and prompt.HoldDuration > 0 then
                            local originalHold    = prompt.HoldDuration
                            prompt.HoldDuration   = 0
                            fireproximityprompt(prompt)
                            task.delay(0.05, function()
                                if prompt and prompt.Parent then prompt.HoldDuration = originalHold end
                            end)
                        else
                            fireproximityprompt(prompt)
                        end
                    end, "Auto Proxi - Fire Prompt")
                end)
            end
        end
        for id, time in pairs(autoProxiCooldowns) do
            if tick() - time > 5 then autoProxiCooldowns[id] = nil end
        end
    end, "Run Auto Proxi")
end

local autoProxiToggle, autoProxiToggleId = InteractTab:Toggle("Auto Proxi (Hold R)", Settings.autoProxi, function(enabled)
    safeCall(function()
        autoProxiEnabled    = enabled
        Settings.autoProxi  = enabled
        autoProxiCooldowns  = {}
        if enabled then
            autoProxiLoop = task.spawn(function()
                while autoProxiEnabled do
                    if isAutoProxiKeyHeld then runAutoProxi() end
                    task.wait(0.05)
                end
            end)
        else
            if autoProxiLoop then task.cancel(autoProxiLoop); autoProxiLoop = nil end
        end
    end, "Auto Proxi Toggle")
end, "Hold R to auto interact with prompts")

InteractTab:Toggle("Instant Interact", Settings.autoProxiInstant, function(enabled)
    safeCall(function()
        autoProxiInstant          = enabled
        Settings.autoProxiInstant = enabled
    end, "Instant Interact Toggle")
end, "Bypass hold duration on prompts")

local autoProxiKeybind = InteractTab:Keybind("Auto Proxi Key", autoProxiKey, function(key, pressed)
    safeCall(function()
        autoProxiKey          = key
        Settings.autoProxiKey = key.Name
    end, "Auto Proxi Keybind")
end, "Key to hold for Auto Proxi")
InteractTab:DependsOn(autoProxiKeybind, autoProxiToggleId)

local finishRoom100Enabled  = false
local finishRoom100Loop     = nil
local elevatorBreakerFound  = false
local finishRoom100Toggle = HotelTab:Toggle("Finish Room 100's Minigame", false, function(enabled)
    safeCall(function()
        finishRoom100Enabled  = enabled
        elevatorBreakerFound  = false
        if enabled then
            Window:Notify({ Text = "[Room 100 Minigame]: Searching for ElevatorBreaker...", Duration = 5, Type = "Warning" })
            finishRoom100Loop = task.spawn(function()
                local emptyFound = false
                while finishRoom100Enabled and not emptyFound do
                    task.wait(0.1)
                    safeCall(function()
                        local currentRooms = workspace:FindFirstChild("CurrentRooms")
                        if not currentRooms then return end
                        for _, room in pairs(currentRooms:GetChildren()) do
                            if room:FindFirstChild("ElevatorBreakerEmpty", true) then
                                emptyFound = true
                                Window:Notify({ Text = "[Room 100]: ElevatorBreakerEmpty found! Waiting for transformation...", Duration = 3, Type = "Success" })
                                break
                            end
                        end
                    end, "Room 100 - Check for Empty")
                end
                while finishRoom100Enabled and not elevatorBreakerFound do
                    task.wait(3)
                    safeCall(function()
                        local currentRooms = workspace:FindFirstChild("CurrentRooms")
                        if not currentRooms then return end
                        for _, room in pairs(currentRooms:GetChildren()) do
                            local elevatorBreaker = room:FindFirstChild("ElevatorBreaker", true)
                            if elevatorBreaker then
                                elevatorBreakerFound = true
                                Window:Notify({ Text = "[Room 100]: ElevatorBreaker found! Starting auto-complete...", Duration = 3, Type = "Success" })
                                task.wait(0.5)
                                local activatePrompt = elevatorBreaker:FindFirstChild("ActivateEventPrompt", true)
                                if activatePrompt and activatePrompt:IsA("ProximityPrompt") then
                                    fireproximityprompt(activatePrompt)
                                    Window:Notify({ Text = "[Room 100]: Activated event prompt!", Duration = 2, Type = "Success" })
                                end
                                break
                            end
                        end
                    end, "Room 100 - Check for Breaker")
                end
                while finishRoom100Enabled and elevatorBreakerFound do
                    task.wait(1)
                    safeCall(function()
                        local RemotesFolder = ReplicatedStorage:WaitForChild("RemotesFolder")
                        RemotesFolder:WaitForChild("EBF"):FireServer()
                    end, "Room 100 - Fire EBF Remote")
                end
            end)
        else
            if finishRoom100Loop then task.cancel(finishRoom100Loop); finishRoom100Loop = nil end
            elevatorBreakerFound = false
        end
    end, "Finish Room 100's Minigame Toggle")
end, "Automatically completes the Room 100 electrical minigame")

do
    local CODE_LENGTH        = 5
    local CODES_PER_BATCH    = 25
    local SOLVER_DELAY       = 0.01
    local REQUIRED_DISTANCE  = 25
    local UPDATE_INTERVAL    = 0.5
    local room50SolverEnabled  = false
    local room50SolverLoop     = nil
    local currentHints         = {}
    local lastNotificationTime = 0
    local function isInRoom50()
        local currentRooms = workspace:FindFirstChild("CurrentRooms")
        return currentRooms and currentRooms:FindFirstChild("50") ~= nil
    end

    local function getRoom50Door()
        local currentRooms = workspace:FindFirstChild("CurrentRooms")
        if not currentRooms then return nil end
        local room50 = currentRooms:FindFirstChild("50")
        return room50 and room50:FindFirstChild("Door")
    end

    local function isNearRoom50Door()
        local character = LocalPlayer.Character
        if not character then return false end
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then return false end
        local door = getRoom50Door()
        if not door then return false end
        local doorPart = door:IsA("BasePart") and door or door:FindFirstChildWhichIsA("BasePart")
        if not doorPart then return false end
        return (hrp.Position - doorPart.Position).Magnitude <= REQUIRED_DISTANCE
    end

    local function getHintNumbers()
        local hintNumbers = {}
        local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if not PlayerGui then return hintNumbers end
        local PermUi = PlayerGui:FindFirstChild("PermUI")
        if not PermUi then return hintNumbers end
        local Hints = PermUi:FindFirstChild("Hints")
        if not Hints then return hintNumbers end
        for _, child in pairs(Hints:GetChildren()) do
            if child:IsA("ImageLabel") and child.Name == "Icon" then
                local textLabel = child:FindFirstChildWhichIsA("TextLabel")
                if textLabel and textLabel.Text then
                    local number = tonumber(textLabel.Text)
                    if number ~= nil then table.insert(hintNumbers, number) end
                end
            end
        end
        return hintNumbers
    end

    local function updateHints()
        local newHints     = getHintNumbers()
        local hintsChanged = (#newHints ~= #currentHints)
        if not hintsChanged then
            for i = 1, #newHints do
                if newHints[i] ~= currentHints[i] then hintsChanged = true; break end
            end
        end
        if hintsChanged then currentHints = newHints; return true, newHints end
        return false, currentHints
    end

    local function generateCodesFromHints(hintNumbers, count)
        local codes = {}
        if #hintNumbers == 0 then return codes end
        for i = 1, count do
            local code = ""
            for j = 1, CODE_LENGTH do
                code = code .. tostring(hintNumbers[math.random(1, #hintNumbers)])
            end
            table.insert(codes, code)
        end
        return codes
    end

    local function tryCode(code)
        safeCall(function()
            local RemotesFolder = ReplicatedStorage:WaitForChild("RemotesFolder")
            RemotesFolder:WaitForChild("PL"):FireServer(code)
        end, "Try Code")
    end

    local function notify50(text, duration, notifType)
        if tick() - lastNotificationTime < 2 then return end
        lastNotificationTime = tick()
        safeCall(function()
            Window:Notify({ Text = text, Duration = duration or 3, Type = notifType or "Success" })
        end, "Notification")
    end

    local function startRoom50Solver()
        safeCall(function()
            if not isInRoom50() then
                notify50("[Room 50]: You're not in Room 50!", 5, "Warning")
                room50SolverEnabled = false
                return
            end
            local hintsChanged, hints = updateHints()
            if #hints == 0 then
                notify50("[Room 50]: No books collected! Collect at least one book first.", 5, "Warning")
                room50SolverEnabled = false
                return
            end

            notify50(string.format("[Room 50]: Solver active! Found %d hints: [%s]", #hints, table.concat(hints, ", ")), 5, "Success")

            local attemptCount       = 0
            local startTime          = tick()
            local lastProgressUpdate = tick()
            local lastHintCheck      = tick()
            while room50SolverEnabled do
                if tick() - lastHintCheck >= UPDATE_INTERVAL then
                    lastHintCheck = tick()
                    local changed, newHints = updateHints()
                    if changed then
                        notify50(string.format("[Room 50]: Hints updated! Now have %d hints: [%s]", #newHints, table.concat(newHints, ", ")), 3, "Success")
                    end
                end
                if not isNearRoom50Door() then
                    if tick() - lastProgressUpdate >= 5 then
                        notify50("[Room 50]: Too far from door! Move closer.", 3, "Warning")
                        lastProgressUpdate = tick()
                    end
                    task.wait(1); continue
                end
                local codes = generateCodesFromHints(currentHints, CODES_PER_BATCH)
                for _, code in ipairs(codes) do
                    if not room50SolverEnabled then break end
                    tryCode(code)
                    attemptCount = attemptCount + 1
                end
                if attemptCount % 1000 == 0 then
                    local elapsed = tick() - startTime
                    local rate    = attemptCount / elapsed
                    notify50(string.format("[Room 50]: Tried %d codes (%.0f codes/sec) | Hints: [%s]", attemptCount, rate, table.concat(currentHints, ", ")), 3, "Success")
                end
                task.wait(SOLVER_DELAY)
            end
        end, "Room 50 Solver Main")
    end

    HotelTab:Toggle("Room 50 Code Solver", false, function(enabled)
        safeCall(function()
            room50SolverEnabled = enabled
            if enabled then
                currentHints     = {}
                room50SolverLoop = task.spawn(startRoom50Solver)
            else
                if room50SolverLoop then task.cancel(room50SolverLoop); room50SolverLoop = nil end
                notify50("[Room 50]: Solver stopped", 2, "Warning")
            end
        end, "Room 50 Solver Toggle")
    end, "Auto-solves Room 50 code by randomly picking from hint numbers")
end

local bypassEnabled = false
local bypassLoop
local ladderESP     = {}
if currentFloor == "Mines" or currentFloor == "Unknown" then
    local minesToggle = MinesTab:Toggle("Anticheat Bypass", Settings.minesAnticheat, function(enabled)
        safeCall(function()
            bypassEnabled          = enabled
            Settings.minesAnticheat = enabled
            if enabled then
                for _, room in pairs(workspace.CurrentRooms:GetChildren()) do
                    safeCall(function()
                        local ladder = room:FindFirstChild("Ladder", true)
                        if ladder then
                            local highlight             = Instance.new("Highlight")
                            highlight.FillColor         = Color3.fromRGB(0, 100, 255)
                            highlight.OutlineColor      = Color3.fromRGB(0, 150, 255)
                            highlight.FillTransparency  = 0.5
                            highlight.OutlineTransparency = 0
                            highlight.Parent            = ladder
                            table.insert(ladderESP, highlight)
                        end
                    end, "Mines Bypass - Ladder ESP")
                end
                bypassLoop = task.spawn(function()
                    while bypassEnabled do
                        task.wait(0.1)
                        safeCall(function()
                            local Character = LocalPlayer.Character
                            if Character then
                                local climbingAttr = Character:GetAttribute("Climbing")
                                if climbingAttr == true then
                                    Window:Notify({ Text = "[Bypass]: Wait 2 seconds, don't move", Duration = 2, Type = "Warning" })
                                    task.wait(0.5)
                                    Character:SetAttribute("Climbing", false)
                                end
                            end
                        end, "Mines Bypass Loop")
                    end
                end)
            else
                if bypassLoop then task.cancel(bypassLoop); bypassLoop = nil end
                for _, highlight in pairs(ladderESP) do
                    safeCall(function()
                        if highlight and highlight.Parent then highlight:Destroy() end
                    end, "Remove Ladder ESP")
                end
                ladderESP = {}
            end
        end, "Mines Anticheat Bypass Toggle")
    end, "Prevents ladder detection")
else
    MinesTab:Label("Mines floor not detected")
    MinesTab:Label("Current floor: " .. currentFloor)
end

local espEnabled    = { Door = false, Objective = false, Entity = false }
local espHighlights = {}
local espUpdateLoop
local function hasESPHighlight(obj, espName)
    if not obj then return true end
    for _, child in pairs(obj:GetChildren()) do
        if (child:IsA("Highlight") or child:IsA("BillboardGui")) and child.Name == espName .. "ESP" then
            return true
        end
    end
    return false
end
local function clearESP(espType)
    safeCall(function()
        if espHighlights[espType] then
            for _, item in pairs(espHighlights[espType]) do
                if item and item.Parent then item:Destroy() end
            end
            espHighlights[espType] = {}
        end
    end, "Clear ESP - " .. espType)
end
local function addESPToObject(obj, espType, color, outlineColor, labelText)
    safeCall(function()
        if not obj or hasESPHighlight(obj, espType) then return end
        if not espHighlights[espType] then espHighlights[espType] = {} end
        local highlight             = Instance.new("Highlight")
        highlight.Name              = espType .. "ESP"
        highlight.FillColor         = color
        highlight.OutlineColor      = outlineColor
        highlight.FillTransparency  = 0.5
        highlight.OutlineTransparency = 0
        highlight.Parent            = obj
        table.insert(espHighlights[espType], highlight)
        if labelText then
            local billboard   = Instance.new("BillboardGui")
            billboard.Name    = espType .. "ESP"
            billboard.AlwaysOnTop = true
            billboard.Size    = UDim2.new(0, 100, 0, 50)
            billboard.StudsOffset = Vector3.new(0, 2, 0)
            billboard.Parent  = obj
            local textLabel   = Instance.new("TextLabel")
            textLabel.Size    = UDim2.new(1, 0, 1, 0)
            textLabel.BackgroundTransparency = 1
            textLabel.Text    = labelText
            textLabel.TextColor3 = color
            textLabel.TextStrokeTransparency = 0
            textLabel.TextScaled = true
            textLabel.Font    = Enum.Font.GothamBold
            textLabel.Parent  = billboard
            table.insert(espHighlights[espType], billboard)
        end
    end, "Add ESP - " .. espType)
end
local function createDoorESP()
    safeCall(function()
        for _, room in pairs(workspace.CurrentRooms:GetChildren()) do
            safeCall(function()
                local door = room:FindFirstChild("Door")
                if door and door:IsA("Model") then
                    addESPToObject(door, "Door", Color3.fromRGB(0, 255, 0), Color3.fromRGB(0, 200, 0), nil)
                end
            end, "Create Door ESP - Room")
        end
    end, "Create Door ESP")
end
local function createObjectiveESP()
    safeCall(function()
        for _, room in pairs(workspace.CurrentRooms:GetChildren()) do
            safeCall(function()
                for _, obj in pairs(room:GetDescendants()) do
                    local nameMap = {
                        KeyObtain             = "Key",
                        FuseObtain            = "Fuse",
                        FuseHolder            = "Fuse",
                        LiveHintBook          = "Book",
                        LeverForGate          = "Lever",
                        LiveBreakerPolePickup = "Breaker",
                        TimerLever            = "Timer",
                        Padlock               = "Lock",
                    }
                    local label = nameMap[obj.Name]
                    if label then
                        addESPToObject(obj, "Objective", Color3.fromRGB(255, 255, 0), Color3.fromRGB(200, 200, 0), label)
                    end
                end
            end, "Create Objective ESP - Room")
        end
    end, "Create Objective ESP")
end
local function createEntityESP()
    safeCall(function()
        local entityMap = {
            RushMoving   = { Color3.fromRGB(255, 0, 0),      Color3.fromRGB(200, 0, 0),      "RUSH"   },
            AmbushMoving = { Color3.fromRGB(255, 100, 0),    Color3.fromRGB(200, 80, 0),     "AMBUSH" },
            Eyes         = { Color3.fromRGB(150, 0, 255),    Color3.fromRGB(120, 0, 200),    "EYES"   },
            Halt         = { Color3.fromRGB(0, 200, 255),    Color3.fromRGB(0, 150, 200),    "HALT"   },
            Screech      = { Color3.fromRGB(255, 255, 255),  Color3.fromRGB(200, 200, 200),  "SCREECH"},
            A60          = { Color3.fromRGB(255, 50, 50),    Color3.fromRGB(200, 30, 30),    "A60"    },
            A120         = { Color3.fromRGB(255, 50, 50),    Color3.fromRGB(200, 30, 30),    "A120"   },
        }
        for _, child in pairs(workspace:GetChildren()) do
            safeCall(function()
                local info = entityMap[child.Name]
                if info and child:IsA("Model") then
                    addESPToObject(child, "Entity", info[1], info[2], info[3])
                end
            end, "Create Entity ESP - Workspace Child")
        end
        for _, room in pairs(workspace.CurrentRooms:GetChildren()) do
            safeCall(function()
                local figureSetup = room:FindFirstChild("FigureSetup")
                if figureSetup then
                    local figureRig = figureSetup:FindFirstChild("FigureRig")
                    if figureRig then
                        addESPToObject(figureRig, "Entity", Color3.fromRGB(255, 0, 0), Color3.fromRGB(200, 0, 0), "FIGURE")
                    end
                end
                local seekSetup = room:FindFirstChild("SeekSetup") or room:FindFirstChild("Seek")
                if seekSetup then
                    local seekModel = seekSetup:FindFirstChild("SeekRig") or seekSetup:FindFirstChild("Seek") or seekSetup
                    if seekModel and seekModel:IsA("Model") then
                        addESPToObject(seekModel, "Entity", Color3.fromRGB(0, 0, 0), Color3.fromRGB(100, 100, 100), "SEEK")
                    end
                end
                local assets = room:FindFirstChild("Assets")
                if assets then
                    for _, obj in pairs(assets:GetChildren()) do
                        if obj.Name == "Snare" then
                            addESPToObject(obj, "Entity", Color3.fromRGB(255, 100, 100), Color3.fromRGB(200, 80, 80), "SNARE")
                        end
                    end
                end
            end, "Create Entity ESP - Room")
        end
    end, "Create Entity ESP")
end
local function cleanupDestroyedESP()
    safeCall(function()
        for espType, highlights in pairs(espHighlights) do
            local validHighlights = {}
            for _, item in pairs(highlights) do
                if item and item.Parent then table.insert(validHighlights, item) end
            end
            espHighlights[espType] = validHighlights
        end
    end, "Cleanup Destroyed ESP")
end
local function startESPUpdateLoop()
    if espUpdateLoop then task.cancel(espUpdateLoop) end
    espUpdateLoop = task.spawn(function()
        while espEnabled.Door or espEnabled.Objective or espEnabled.Entity do
            task.wait(0.5)
            cleanupDestroyedESP()
            if espEnabled.Door      then createDoorESP()      end
            if espEnabled.Objective then createObjectiveESP() end
            if espEnabled.Entity    then createEntityESP()    end
        end
    end)
end
ESPTab:Dropdown("ESP Types", {"Door", "Objective", "Entity"}, function(selected)
    safeCall(function()
        local types = {
            { key = "Door",      setting = "espDoor",      create = createDoorESP      },
            { key = "Objective", setting = "espObjective",  create = createObjectiveESP },
            { key = "Entity",    setting = "espEntity",     create = createEntityESP    },
        }
        for _, t in ipairs(types) do
            if selected[t.key] and not espEnabled[t.key] then
                espEnabled[t.key]  = true
                Settings[t.setting] = true
                t.create()
                startESPUpdateLoop()
            elseif not selected[t.key] and espEnabled[t.key] then
                espEnabled[t.key]  = false
                Settings[t.setting] = false
                clearESP(t.key)
            end
        end
        if not espEnabled.Door and not espEnabled.Objective and not espEnabled.Entity then
            if espUpdateLoop then task.cancel(espUpdateLoop); espUpdateLoop = nil end
        end
    end, "ESP Dropdown")
end, "Select ESP types")

local entityNotifierEnabled = false
local notifiedEntities      = {}
ESPTab:Toggle("Entity Notifier", Settings.entityNotifier, function(enabled)
    safeCall(function()
        entityNotifierEnabled    = enabled
        Settings.entityNotifier  = enabled
        if not enabled then notifiedEntities = {} end
    end, "Entity Notifier Toggle")
end, "Get notifications when entities spawn")
task.spawn(function()
    local entityNotifyList = {
        { name = "RushMoving",   text = "Rush is coming!",    type = "Error"   },
        { name = "AmbushMoving", text = "Ambush is coming!",  type = "Error"   },
        { name = "Eyes",         text = "Eyes has appeared!", type = "Error"   },
        { name = "Halt",         text = "Halt has appeared!", type = "Warning" },
    }
    while true do
        task.wait(0.5)
        if entityNotifierEnabled then
            safeCall(function()
                for _, e in ipairs(entityNotifyList) do
                    local model = workspace:FindFirstChild(e.name)
                    if model and not notifiedEntities[e.name] then
                        notifiedEntities[e.name] = true
                        Window:Notify({ Text = e.text, Duration = 5, Type = e.type })
                    elseif not model and notifiedEntities[e.name] then
                        notifiedEntities[e.name] = nil
                    end
                end
            end, "Entity Notifier Loop")
        end
    end
end)

do
    local desiredFOV   = Settings.fov
    local fovConnection
    fovConnection = RunService.RenderStepped:Connect(function()
        safeCall(function()
            local camera = workspace.CurrentCamera
            if camera and camera.FieldOfView ~= desiredFOV then
                camera.FieldOfView = desiredFOV
            end
        end, "FOV RenderStepped")
    end)
    DisplayTab:Slider("FOV", 70, 120, Settings.fov, function(value)
        safeCall(function()
            desiredFOV      = value
            Settings.fov    = value
        end, "FOV Slider")
    end, "Adjust field of view")
    getgenv()._ZeScriptFovConn = fovConnection
end

-- ══════════════════════════════════════════════
--  SETTINGS CATEGORY
-- ══════════════════════════════════════════════

SettingsCategory:ThemePicker("UI Theme", function(themeName, themeData)
    safeCall(function()
        Settings.theme = themeName
        Window:Notify({ Text = "Theme changed to " .. themeName, Duration = 2, Type = "Success" })
    end, "Theme Picker")
end, "Choose color theme")
SettingsCategory:Keybind("Toggle UI Key", Enum.KeyCode.RightShift, function(key, pressed)
end, "Key to open/close UI")
SettingsCategory:Toggle("Auto Load Settings", Settings.autoLoad, function(enabled)
    safeCall(function()
        Settings.autoLoad = enabled
        saveSettings()
    end, "Auto Load Settings Toggle")
end, "Automatically load settings on script start")
SettingsCategory:Button("Save Settings", function()
    safeCall(function()
        if saveSettings() then
            Window:Notify({ Text = "Settings saved!", Duration = 2, Type = "Success" })
        else
            Window:Notify({ Text = "Failed to save settings", Duration = 2, Type = "Error" })
        end
    end, "Save Settings Button")
end, "Save current settings to file")
SettingsCategory:Button("Load Settings", function()
    safeCall(function()
        if loadSettings() then
            Window:Notify({ Text = "Settings loaded!", Duration = 3, Type = "Success" })
        else
            Window:Notify({ Text = "No saved settings found", Duration = 2, Type = "Warning" })
        end
    end, "Load Settings Button")
end, "Load settings from file")

local function destroyScript()
    safeCall(function()
        if lightingConnection then lightingConnection:Disconnect() end
        if getgenv()._ZeScriptFovConn then getgenv()._ZeScriptFovConn:Disconnect() end
        local loops = { spoofCrouchLoop, antiEyesLoop, antiSpeedLoop, bypassLoop, speedLoop,
                        noAccelLoop, autoProxiLoop, doorReachLoop, espUpdateLoop,
                        godModeDistanceLoop, figureGodModeLoop, antiGKLoop,
                        anticheatManipLoop, autoFinishDailyLoop }
        for _, loop in ipairs(loops) do
            if loop then pcall(task.cancel, loop) end
        end
        clearESP("Door"); clearESP("Objective"); clearESP("Entity")
        local Character = LocalPlayer and LocalPlayer.Character
        if Character then
            local Humanoid = Character:FindFirstChild("Humanoid")
            if Humanoid then Humanoid.WalkSpeed = originalWalkSpeed end
            local hrp = Character:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.CustomPhysicalProperties = originalHrpProps end
            if clonedCollision then clonedCollision:Destroy() end
            if godModeEnabled then restoreGodMode(Character) end
        end
        if fullbrightEnabled then
            local Lighting = game:GetService("Lighting")
            for property, value in pairs(originalLighting) do Lighting[property] = value end
        end
        if screechDisabled and screechOriginalParent then
            local screech = ReplicatedStorage.Entities:FindFirstChild("Screech")
            if screech then screech.Parent = screechOriginalParent end
        end
        getgenv().ZeScriptLoaded   = false
        getgenv()._ZeScriptFovConn = nil
        Window:Notify({ Text = "Script destroyed!", Duration = 3, Type = "Warning" })
        task.wait(0.5)
        if Window.Destroy then Window:Destroy() end
    end, "Destroy Script")
end
SettingsCategory:Button("Destroy Script", function()
    destroyScript()
end, "Remove script and restore settings")
SettingsCategory:Button("Reset All Settings", function()
    safeCall(function()
        Settings = {
            spoofCrouch = false, antiEyes = false, disableScreech = false,
            disableSnare = false, objectBypass = false, noAccel = false,
            autoProxi = false, autoProxiInstant = true, autoProxiKey = "R",
            proximityReach = 0, doorReach = false, doorReachDistance = 25,
            antiSpeedBypass = false, speed = false, speedValue = 16,
            minesAnticheat = false, espDoor = false, espObjective = false,
            espEntity = false, entityNotifier = false, fullbright = false,
            fov = 70, theme = "Purple", autoLoad = false, godMode = false
        }
        Window:Notify({ Text = "Settings reset!", Duration = 2, Type = "Success" })
    end, "Reset All Settings Button")
end, "Reset all settings to default")
SettingsCategory:Button("Hide UI", function()
    safeCall(function() Window:Hide() end, "Hide UI Button")
end, "Hide UI - press toggle key to show")
SettingsCategory:Label("ZeScript Doors v1.4 (Reorganized UI)")
SettingsCategory:Label("Floor: " .. currentFloor)

if Settings.autoLoad then
    local loaded = loadSettings()
    if loaded then
        Window:Notify({ Text = "Auto-loaded settings!", Duration = 2, Type = "Success" })
    end
end
wait(0.2)
Window:Show()
