-- Cargar script principal
loadstring(game:HttpGet("https://api.jnkie.com/api/v1/luascripts/public/ef9b5a30ec84e201b585c3ef1850d264b216441eab77257f0e9184de826cc47e/download"))()

task.wait(1) -- Espera a que el script principal cargue

-- ============================================
-- ESP Entity + Entity Notifier - Doors
-- ============================================

-- Variables ESP
local espEnabled = { Entity = true }
local espHighlights = {}
local espUpdateLoop

local function hasESPHighlight(obj, espName)
    if not obj then return true end
    for _, child in pairs(obj:GetChildren()) do
        if child:IsA("Highlight") and child.Name == espName .. "ESP" then
            return true
        end
        if child:IsA("BillboardGui") and child.Name == espName .. "ESP" then
            return true
        end
    end
    return false
end

local function clearESP(espType)
    local ok, err = pcall(function()
        if espHighlights[espType] then
            for _, item in pairs(espHighlights[espType]) do
                if item and item.Parent then
                    item:Destroy()
                end
            end
            espHighlights[espType] = {}
        end
    end)
    if not ok then warn("[ESP Clear Error]: " .. tostring(err)) end
end

local function addESPToObject(obj, espType, color, outlineColor, labelText)
    local ok, err = pcall(function()
        if not obj or hasESPHighlight(obj, espType) then return end

        if not espHighlights[espType] then
            espHighlights[espType] = {}
        end

        local highlight = Instance.new("Highlight")
        highlight.Name = espType .. "ESP"
        highlight.FillColor = color
        highlight.OutlineColor = outlineColor
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        highlight.Parent = obj
        table.insert(espHighlights[espType], highlight)

        if labelText then
            local billboard = Instance.new("BillboardGui")
            billboard.Name = espType .. "ESP"
            billboard.AlwaysOnTop = true
            billboard.Size = UDim2.new(0, 100, 0, 50)
            billboard.StudsOffset = Vector3.new(0, 2, 0)
            billboard.Parent = obj

            local textLabel = Instance.new("TextLabel")
            textLabel.Size = UDim2.new(1, 0, 1, 0)
            textLabel.BackgroundTransparency = 1
            textLabel.Text = labelText
            textLabel.TextColor3 = color
            textLabel.TextStrokeTransparency = 0
            textLabel.TextScaled = true
            textLabel.Font = Enum.Font.GothamBold
            textLabel.Parent = billboard

            table.insert(espHighlights[espType], billboard)
        end
    end)
    if not ok then warn("[ESP Add Error]: " .. tostring(err)) end
end

local function createEntityESP()
    local ok, err = pcall(function()
        -- Entidades en workspace (Rush, Ambush, Eyes, Halt, Screech, A60, A120)
        for _, child in pairs(workspace:GetChildren()) do
            pcall(function()
                if child.Name == "RushMoving" and child:IsA("Model") then
                    addESPToObject(child, "Entity", Color3.fromRGB(255, 0, 0), Color3.fromRGB(200, 0, 0), "RUSH")
                elseif child.Name == "AmbushMoving" and child:IsA("Model") then
                    addESPToObject(child, "Entity", Color3.fromRGB(255, 100, 0), Color3.fromRGB(200, 80, 0), "AMBUSH")
                elseif child.Name == "Eyes" and child:IsA("Model") then
                    addESPToObject(child, "Entity", Color3.fromRGB(150, 0, 255), Color3.fromRGB(120, 0, 200), "EYES")
                elseif child.Name == "Halt" and child:IsA("Model") then
                    addESPToObject(child, "Entity", Color3.fromRGB(0, 200, 255), Color3.fromRGB(0, 150, 200), "HALT")
                elseif child.Name == "Screech" and child:IsA("Model") then
                    addESPToObject(child, "Entity", Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 200, 200), "SCREECH")
                elseif child.Name == "A60" or child.Name == "A120" then
                    addESPToObject(child, "Entity", Color3.fromRGB(255, 50, 50), Color3.fromRGB(200, 30, 30), child.Name)
                end
            end)
        end

        -- Figure, Seek, Snare en habitaciones
        for _, room in pairs(workspace.CurrentRooms:GetChildren()) do
            pcall(function()
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
            end)
        end
    end)
    if not ok then warn("[Create Entity ESP Error]: " .. tostring(err)) end
end

local function cleanupDestroyedESP()
    pcall(function()
        for espType, highlights in pairs(espHighlights) do
            local valid = {}
            for _, item in pairs(highlights) do
                if item and item.Parent then
                    table.insert(valid, item)
                end
            end
            espHighlights[espType] = valid
        end
    end)
end

-- Loop ESP Entity (siempre activo)
espUpdateLoop = task.spawn(function()
    while espEnabled.Entity do
        task.wait(0.5)
        cleanupDestroyedESP()
        createEntityESP()
    end
end)

-- ============================================
-- Entity Notifier
-- ============================================

local entityNotifierEnabled = true
local notifiedEntities = {}

local function notify(text)
    warn("[Entity Notifier] " .. text)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "⚠️ Entity Alert",
        Text = text,
        Duration = 5
    })
end

task.spawn(function()
    while true do
        task.wait(0.5)
        if entityNotifierEnabled then
            local ok, err = pcall(function()
                -- Rush
                local rushMoving = workspace:FindFirstChild("RushMoving")
                if rushMoving and not notifiedEntities["RushMoving"] then
                    notifiedEntities["RushMoving"] = true
                    notify("Rush is coming!")
                elseif not rushMoving and notifiedEntities["RushMoving"] then
                    notifiedEntities["RushMoving"] = nil
                end

                -- Ambush
                local ambushMoving = workspace:FindFirstChild("AmbushMoving")
                if ambushMoving and not notifiedEntities["AmbushMoving"] then
                    notifiedEntities["AmbushMoving"] = true
                    notify("Ambush is coming!")
                elseif not ambushMoving and notifiedEntities["AmbushMoving"] then
                    notifiedEntities["AmbushMoving"] = nil
                end

                -- Eyes
                local eyes = workspace:FindFirstChild("Eyes")
                if eyes and not notifiedEntities["Eyes"] then
                    notifiedEntities["Eyes"] = true
                    notify("Eyes has appeared!")
                elseif not eyes and notifiedEntities["Eyes"] then
                    notifiedEntities["Eyes"] = nil
                end

                -- Halt
                local halt = workspace:FindFirstChild("Halt")
                if halt and not notifiedEntities["Halt"] then
                    notifiedEntities["Halt"] = true
                    notify("Halt has appeared!")
                elseif not halt and notifiedEntities["Halt"] then
                    notifiedEntities["Halt"] = nil
                end
            end)
            if not ok then
                warn("[Entity Notifier Error]: " .. tostring(err))
            end
        end
    end
end)

print("[Entity ESP + Notifier] Running!")
