-- ✅ Script: Botón en pantalla para cargar Nameless Admin desde GitHub
-- Funciona en Xeno Executor

-- Crear GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NamelessButtonGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = game:GetService("CoreGui") -- Usa CoreGui para que no desaparezca

-- Crear botón
local button = Instance.new("TextButton")
button.Name = "LoadNameless"
button.Size = UDim2.new(0, 200, 0, 50)
button.Position = UDim2.new(0.5, -100, 0.5, -25)
button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
button.BorderSizePixel = 0
button.Text = "Cargar Nameless Admin"
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Font = Enum.Font.GothamBold
button.TextSize = 16
button.Parent = screenGui

-- Función al hacer clic
button.MouseButton1Click:Connect(function()
    -- Intentar cargar Nameless Admin
    local success, err = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ltseverydayyou/Nameless-Admin/main/Source.lua"))()
    end)

    if success then
        button.Text = "¡Nameless cargado!"
        wait(1)
        screenGui:Destroy() -- Elimina el botón de pantalla
    else
        button.Text = "Error al cargar"
        warn("Error cargando Nameless Admin:", err)
    end
end)