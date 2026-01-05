-- ===== ESP ZOMBIES + AIMBOT + PERSISTENCIA =====
-- Creator = Nobodxy85-bit
-- Version: 2.1 Fixed

print("🔄 Iniciando ESP Script...")

-- ===== VERIFICAR SI YA ESTÁ CARGADO =====
if _G.ESP_ZOMBIES_ACTIVE then
    warn("⚠️ ESP Script ya está activo en este servidor")
    return
end
_G.ESP_ZOMBIES_ACTIVE = true

-- ===== INICIALIZAR CONFIGURACIÓN =====
if not _G.ESP_CONFIG then
    _G.ESP_CONFIG = {
        espEnabled = false,
        aimbotEnabled = false,
        firstTimeKeyboard = true
    }
    print("📝 Configuración inicial creada")
else
    print("📝 Configuración encontrada:", game:GetService("HttpService"):JSONEncode(_G.ESP_CONFIG))
end

-- ===== SERVICIOS =====
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
print("👤 Jugador:", player.Name)

-- ===== CONFIGURACIÓN =====
local ALERT_DISTANCE = 20
local AIM_FOV = 30
local SMOOTHNESS = 0.15

local enabled = _G.ESP_CONFIG.espEnabled
local aimbotEnabled = _G.ESP_CONFIG.aimbotEnabled
local firstTimeKeyboard = _G.ESP_CONFIG.firstTimeKeyboard

local Camera = workspace.CurrentCamera

-- ===== CACHÉ =====
local espObjects = {}
local cachedZombies = {}
local cachedBoxes = {}
local connections = {}

print("✅ Variables inicializadas")

-- ===== FUNCIÓN DE PERSISTENCIA =====
local function setupPersistence()
    print("🔧 Configurando persistencia...")
    
    local queueFunc = queue_on_teleport or 
                     (syn and syn.queue_on_teleport) or 
                     (fluxus and fluxus.queue_on_teleport)
    
    if not queueFunc then
        warn("⚠️ queue_on_teleport no disponible")
        return false
    end
    
    player.OnTeleport:Connect(function(state)
        if state == Enum.TeleportState.Started then
            print("🚀 Teleport detectado - guardando estado...")
            
            _G.ESP_CONFIG.espEnabled = enabled
            _G.ESP_CONFIG.aimbotEnabled = aimbotEnabled
            _G.ESP_CONFIG.firstTimeKeyboard = firstTimeKeyboard
            
            local code = [[
                repeat task.wait() until game:IsLoaded()
                task.wait(1)
                print("🔄 Servidor nuevo detectado")
                
                _G.ESP_ZOMBIES_ACTIVE = nil
                
                local scriptUrl = "]] .. "https://raw.githubusercontent.com/YOUR_REPO/script.lua" .. [["
                
                -- Si tienes el código guardado localmente
                if _G.ESP_FULL_CODE then
                    print("📥 Ejecutando código guardado...")
                    local success, err = pcall(loadstring(_G.ESP_FULL_CODE))
                    if success then
                        print("✅ Script recargado")
                    else
                        warn("❌ Error:", err)
                    end
                end
            ]]
            
            local success, err = pcall(function()
                queueFunc(code)
            end)
            
            if success then
                print("✅ Auto-recarga programada")
            else
                warn("❌ Error al programar recarga:", err)
            end
        end
    end)
    
    return true
end

-- ===== CREAR GUI =====
print("🎨 Creando GUI...")

local PlayerGui = player:WaitForChild("PlayerGui")
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ESP_GUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

print("✅ ScreenGui creado")

-- ===== ALERTA =====
local AlertText = Instance.new("TextLabel")
AlertText.Name = "AlertText"
AlertText.Size = UDim2.new(0, 360, 0, 50)
AlertText.Position = UDim2.new(0.5, -180, 0.12, 0)
AlertText.BackgroundTransparency = 1
AlertText.TextColor3 = Color3.fromRGB(255, 0, 0)
AlertText.Font = Enum.Font.GothamBold
AlertText.TextSize = 30
AlertText.TextStrokeTransparency = 0.5
AlertText.Visible = false
AlertText.ZIndex = 10
AlertText.Parent = ScreenGui

-- ===== BOTÓN CIRCULAR =====
local CircleButton = Instance.new("TextButton")
CircleButton.Name = "CircleButton"
CircleButton.Size = UDim2.new(0, 80, 0, 80)
CircleButton.Position = UDim2.new(0.5, -40, 0.10, 0)
CircleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
CircleButton.BackgroundTransparency = 0.3
CircleButton.Text = "⚙️"
CircleButton.TextSize = 35
CircleButton.Font = Enum.Font.GothamBold
CircleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CircleButton.ZIndex = 10
CircleButton.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(1, 0)
UICorner.Parent = CircleButton

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(255, 255, 255)
UIStroke.Thickness = 3
UIStroke.Parent = CircleButton

print("✅ Botón circular creado")

-- ===== HACER ARRASTRABLE =====
local dragging = false
local dragInput, dragStart, startPos

CircleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or 
       input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = CircleButton.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

CircleButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or 
       input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        CircleButton.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- ===== MENÚ =====
local MobileMenu = Instance.new("Frame")
MobileMenu.Name = "MobileMenu"
MobileMenu.Size = UDim2.new(0, 280, 0, 260)
MobileMenu.Position = UDim2.new(0.5, -140, 0.5, -130)
MobileMenu.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MobileMenu.BackgroundTransparency = 0.1
MobileMenu.BorderSizePixel = 0
MobileMenu.Visible = false
MobileMenu.ZIndex = 11
MobileMenu.Parent = ScreenGui

local MenuCorner = Instance.new("UICorner")
MenuCorner.CornerRadius = UDim.new(0, 15)
MenuCorner.Parent = MobileMenu

local MenuStroke = Instance.new("UIStroke")
MenuStroke.Color = Color3.fromRGB(255, 255, 255)
MenuStroke.Thickness = 2
MenuStroke.Parent = MobileMenu

-- ===== TÍTULO =====
local MenuTitle = Instance.new("TextLabel")
MenuTitle.Name = "MenuTitle"
MenuTitle.Size = UDim2.new(1, 0, 0, 40)
MenuTitle.BackgroundTransparency = 1
MenuTitle.Text = "MENU DE CONTROL"
MenuTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
MenuTitle.Font = Enum.Font.GothamBold
MenuTitle.TextSize = 18
MenuTitle.ZIndex = 12
MenuTitle.Parent = MobileMenu

-- ===== BOTÓN ESP =====
local ESPButton = Instance.new("TextButton")
ESPButton.Name = "ESPButton"
ESPButton.Size = UDim2.new(0, 240, 0, 50)
ESPButton.Position = UDim2.new(0.5, -120, 0, 55)
ESPButton.BackgroundColor3 = enabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
ESPButton.Text = enabled and "ESP: ON" or "ESP: OFF"
ESPButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ESPButton.Font = Enum.Font.GothamBold
ESPButton.TextSize = 20
ESPButton.ZIndex = 12
ESPButton.Parent = MobileMenu

local ESPCorner = Instance.new("UICorner")
ESPCorner.CornerRadius = UDim.new(0, 10)
ESPCorner.Parent = ESPButton

-- ===== BOTÓN AIMBOT =====
local AimbotButton = Instance.new("TextButton")
AimbotButton.Name = "AimbotButton"
AimbotButton.Size = UDim2.new(0, 240, 0, 50)
AimbotButton.Position = UDim2.new(0.5, -120, 0, 115)
AimbotButton.BackgroundColor3 = aimbotEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
AimbotButton.Text = aimbotEnabled and "AIMBOT: ON" or "AIMBOT: OFF"
AimbotButton.TextColor3 = Color3.fromRGB(255, 255, 255)
AimbotButton.Font = Enum.Font.GothamBold
AimbotButton.TextSize = 20
AimbotButton.ZIndex = 12
AimbotButton.Parent = MobileMenu

local AimbotCorner = Instance.new("UICorner")
AimbotCorner.CornerRadius = UDim.new(0, 10)
AimbotCorner.Parent = AimbotButton

-- ===== BOTÓN SERVER HOP =====
local ServerHopButton = Instance.new("TextButton")
ServerHopButton.Name = "ServerHopButton"
ServerHopButton.Size = UDim2.new(0, 240, 0, 50)
ServerHopButton.Position = UDim2.new(0.5, -120, 0, 175)
ServerHopButton.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
ServerHopButton.Text = "🔄 CAMBIAR SERVER"
ServerHopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ServerHopButton.Font = Enum.Font.GothamBold
ServerHopButton.TextSize = 18
ServerHopButton.ZIndex = 12
ServerHopButton.Parent = MobileMenu

local ServerHopCorner = Instance.new("UICorner")
ServerHopCorner.CornerRadius = UDim.new(0, 10)
ServerHopCorner.Parent = ServerHopButton

-- ===== TEXTO DE ESTADO =====
local StatusText = Instance.new("TextLabel")
StatusText.Name = "StatusText"
StatusText.Size = UDim2.new(0, 300, 0, 35)
StatusText.Position = UDim2.new(0.5, -150, 0.92, 0)
StatusText.BackgroundTransparency = 0.5
StatusText.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
StatusText.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusText.Font = Enum.Font.GothamBold
StatusText.TextSize = 18
StatusText.Visible = false
StatusText.ZIndex = 10
StatusText.Parent = ScreenGui

-- ===== BIENVENIDA =====
local WelcomeText = Instance.new("TextLabel")
WelcomeText.Name = "WelcomeText"
WelcomeText.Size = UDim2.new(0, 400, 0, 35)
WelcomeText.Position = UDim2.new(0.5, -200, 0.85, 0)
WelcomeText.BackgroundTransparency = 0.3
WelcomeText.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
WelcomeText.Text = "Creator = Nobodxy85-bit  :D"
WelcomeText.TextColor3 = Color3.fromRGB(255, 255, 255)
WelcomeText.Font = Enum.Font.GothamBold
WelcomeText.TextSize = 18
WelcomeText.ZIndex = 10
WelcomeText.Parent = ScreenGui

local WelcomeCorner = Instance.new("UICorner")
WelcomeCorner.CornerRadius = UDim.new(0, 10)
WelcomeCorner.Parent = WelcomeText

task.spawn(function()
    task.wait(3)
    for i = 0, 1, 0.03 do
        WelcomeText.TextTransparency = i
        WelcomeText.BackgroundTransparency = 0.3 + (0.7 * i)
        task.wait(0.05)
    end
    WelcomeText.Visible = false
end)

print("✅ GUI completo creado")

-- ===== FUNCIONES DE UTILIDAD =====
local function showStatus(text, color)
    print("📢", text)
    StatusText.Text = text
    StatusText.TextColor3 = color
    StatusText.Visible = true
    StatusText.TextTransparency = 0
    StatusText.BackgroundTransparency = 0.5
    
    task.spawn(function()
        task.wait(2)
        for i = 0, 1, 0.05 do
            StatusText.TextTransparency = i
            StatusText.BackgroundTransparency = 0.5 + (0.5 * i)
            task.wait(0.03)
        end
        StatusText.Visible = false
    end)
end

-- ===== SERVER HOP =====
local function serverHop()
    print("🔄 Iniciando Server Hop...")
    showStatus("🔄 Buscando servidor...", Color3.fromRGB(100, 150, 255))
    
    _G.ESP_CONFIG.espEnabled = enabled
    _G.ESP_CONFIG.aimbotEnabled = aimbotEnabled
    _G.ESP_CONFIG.firstTimeKeyboard = firstTimeKeyboard
    
    task.spawn(function()
        local success, err = pcall(function()
            local url = string.format(
                "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100",
                game.PlaceId
            )
            
            print("🌐 Consultando:", url)
            local response = game:HttpGet(url)
            local data = HttpService:JSONDecode(response)
            
            if not data or not data.data then
                showStatus("❌ No se encontraron servidores", Color3.fromRGB(255, 0, 0))
                return
            end
            
            local servers = {}
            for _, server in ipairs(data.data) do
                if server.id ~= game.JobId and server.playing < server.maxPlayers then
                    table.insert(servers, server.id)
                end
            end
            
            print("🎲 Servidores disponibles:", #servers)
            
            if #servers == 0 then
                showStatus("❌ No hay servidores disponibles", Color3.fromRGB(255, 0, 0))
                return
            end
            
            local randomServer = servers[math.random(1, #servers)]
            print("✈️ Teleportando a servidor:", randomServer)
            TeleportService:TeleportToPlaceInstance(game.PlaceId, randomServer, player)
        end)
        
        if not success then
            showStatus("❌ Error al cambiar servidor", Color3.fromRGB(255, 0, 0))
            warn("❌ Server Hop Error:", err)
        end
    end)
end

-- ===== ESP FUNCTIONS =====
local function addOutline(part, color)
    if not part:IsA("BasePart") or part:FindFirstChild("ESP_Highlight") then 
        return 
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.Adornee = part
    highlight.FillTransparency = 1
    highlight.OutlineTransparency = 0
    highlight.OutlineColor = color
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = part

    table.insert(espObjects, highlight)
end

local function createZombieESP(zombie)
    if cachedZombies[zombie] then return end
    cachedZombies[zombie] = true

    for _, part in ipairs(zombie:GetChildren()) do
        if part:IsA("BasePart") then
            addOutline(part, Color3.fromRGB(255, 0, 0))
        end
    end
end

local function createBoxESP(box)
    if cachedBoxes[box] then return end
    cachedBoxes[box] = true

    for _, part in ipairs(box:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "Part" then
            addOutline(part, Color3.fromRGB(0, 200, 255))
        end
    end
end

local function clearESP()
    print("🧹 Limpiando ESP...")
    for _, obj in ipairs(espObjects) do
        pcall(function()
            obj:Destroy()
        end)
    end
    table.clear(espObjects)
    table.clear(cachedZombies)
    table.clear(cachedBoxes)
end

local function enableESP()
    print("👁️ Activando ESP...")
    local baddies = workspace:FindFirstChild("Baddies")
    if baddies then
        print("🧟 Zombies encontrados:", #baddies:GetChildren())
        for _, zombie in ipairs(baddies:GetChildren()) do
            createZombieESP(zombie)
        end
        
        local zombieConnection = baddies.ChildAdded:Connect(function(zombie)
            task.wait(0.1)
            if enabled then
                createZombieESP(zombie)
            end
        end)
        table.insert(connections, zombieConnection)
    else
        warn("⚠️ No se encontró la carpeta 'Baddies'")
    end

    local interact = workspace:FindFirstChild("Interact")
    if interact then
        for _, obj in ipairs(interact:GetChildren()) do
            if obj.Name == "MysteryBox" then
                createBoxESP(obj)
                print("📦 Mystery Box encontrado")
            end
        end
    end
end

local function toggleESP(fromKeyboard)
    print("🔄 Toggle ESP -", fromKeyboard and "Teclado" or "Botón")
    enabled = not enabled
    _G.ESP_CONFIG.espEnabled = enabled

    if fromKeyboard and firstTimeKeyboard then
        CircleButton.Visible = false
        firstTimeKeyboard = false
        _G.ESP_CONFIG.firstTimeKeyboard = false
    end

    if enabled then
        enableESP()
        showStatus("ESP | ACTIVADO", Color3.fromRGB(0, 255, 0))
        ESPButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        ESPButton.Text = "ESP: ON"
    else
        clearESP()
        AlertText.Visible = false
        showStatus("ESP | DESACTIVADO", Color3.fromRGB(255, 0, 0))
        ESPButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        ESPButton.Text = "ESP: OFF"
    end
end

local function toggleAimbot()
    print("🔄 Toggle Aimbot")
    aimbotEnabled = not aimbotEnabled
    _G.ESP_CONFIG.aimbotEnabled = aimbotEnabled
    
    if aimbotEnabled then
        showStatus("AIMBOT | ACTIVADO", Color3.fromRGB(0, 255, 0))
        AimbotButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        AimbotButton.Text = "AIMBOT: ON"
    else
        showStatus("AIMBOT | DESACTIVADO", Color3.fromRGB(255, 0, 0))
        AimbotButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        AimbotButton.Text = "AIMBOT: OFF"
    end
end

-- ===== AIMBOT =====
local function getClosestZombieToCursor()
    local closest = nil
    local shortest = math.huge
    local mousePos = UserInputService:GetMouseLocation()

    local baddies = workspace:FindFirstChild("Baddies")
    if not baddies then return nil end

    for _, zombie in ipairs(baddies:GetChildren()) do
        local head = zombie:FindFirstChild("Head")
        local humanoid = zombie:FindFirstChildOfClass("Humanoid")

        if head and humanoid and humanoid.Health > 0 then
            local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
            if onScreen then
                local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                if distance < AIM_FOV and distance < shortest then
                    shortest = distance
                    closest = head
                end
            end
        end
    end

    return closest
end

-- ===== EVENTOS =====
CircleButton.MouseButton1Click:Connect(function()
    print("🖱️ Botón circular clickeado")
    MobileMenu.Visible = not MobileMenu.Visible
    
    if MobileMenu.Visible then
        CircleButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        UIStroke.Color = Color3.fromRGB(0, 200, 255)
    else
        CircleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        UIStroke.Color = Color3.fromRGB(255, 255, 255)
    end
end)

ESPButton.MouseButton1Click:Connect(function()
    print("🖱️ Botón ESP clickeado")
    toggleESP(false)
end)

AimbotButton.MouseButton1Click:Connect(function()
    print("🖱️ Botón Aimbot clickeado")
    toggleAimbot()
end)

ServerHopButton.MouseButton1Click:Connect(function()
    print("🖱️ Botón Server Hop clickeado")
    serverHop()
end)

-- ===== TECLADO =====
local keyboardConnection = UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end

    if input.KeyCode == Enum.KeyCode.T then
        print("⌨️ Tecla T presionada")
        toggleESP(true)
    elseif input.KeyCode == Enum.KeyCode.C then
        print("⌨️ Tecla C presionada")
        toggleAimbot()
    elseif input.KeyCode == Enum.KeyCode.H then
        print("⌨️ Tecla H presionada")
        serverHop()
    end
end)
table.insert(connections, keyboardConnection)

print("✅ Controles conectados")

-- ===== BUCLE PRINCIPAL =====
local renderConnection = RunService.RenderStepped:Connect(function()
    -- Alerta
    if enabled then
        local character = player.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        local baddies = workspace:FindFirstChild("Baddies")

        if hrp and baddies then
            local count = 0

            for _, zombie in ipairs(baddies:GetChildren()) do
                local root = zombie:FindFirstChild("HumanoidRootPart")
                local humanoid = zombie:FindFirstChildOfClass("Humanoid")

                if root and humanoid and humanoid.Health > 0 then
                    local distance = (hrp.Position - root.Position).Magnitude
                    if distance <= ALERT_DISTANCE then
                        count = count + 1
                    end
                end
            end

            if count > 0 then
                AlertText.Text = "⚠ ZOMBIE CERCA (x" .. count .. ")"
                AlertText.Visible = true
            else
                AlertText.Visible = false
            end
        end
    else
        AlertText.Visible = false
    end

    -- Aimbot
    if aimbotEnabled then
        local target = getClosestZombieToCursor()
        if target then
            local targetCFrame = CFrame.new(Camera.CFrame.Position, target.Position)
            Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, SMOOTHNESS)
        end
    end
end)
table.insert(connections, renderConnection)

print("✅ Bucle principal iniciado")

-- ===== LIMPIEZA =====
local function cleanup()
    print("🧹 Limpiando todo...")
    
    for _, connection in ipairs(connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    
    clearESP()
    table.clear(connections)
end

Players.PlayerRemoving:Connect(function(plr)
    if plr == player then
        cleanup()
    end
end)

-- ===== PERSISTENCIA =====
local persistenceOk = setupPersistence()
if persistenceOk then
    print("✅ Persistencia configurada")
else
    print("⚠️ Persistencia no disponible")
end

-- ===== AUTO-ACTIVAR =====
task.spawn(function()
    task.wait(1)
    
    print("🔍 Verificando auto-activación...")
    print("ESP Config guardado:", _G.ESP_CONFIG.espEnabled)
    print("Aimbot Config guardado:", _G.ESP_CONFIG.aimbotEnabled)
    
    if _G.ESP_CONFIG.espEnabled and not enabled then
        print("🔄 Reactivando ESP...")
        toggleESP(false)
    end
    
    if _G.ESP_CONFIG.aimbotEnabled and not aimbotEnabled then
        print("🔄 Reactivando Aimbot...")
        toggleAimbot()
    end
end)

-- ===== GUARDAR CÓDIGO COMPLETO =====
_G.ESP_FULL_CODE = game:HttpGet("https://raw.githubusercontent.com/YOUR_URL/script.lua")

print("="..string.rep("=", 50))
print("✅ ESP SCRIPT CARGADO EXITOSAMENTE")
print("="..string.rep("=", 50))
print("📌 CONTROLES:")
print("   T = Toggle ESP")
print("   C = Toggle Aimbot")
print("   H = Server Hop")
print("   ⚙️ = Menú")
print("="..string.rep("=", 50))
